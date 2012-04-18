open util/ordering[Time]
sig Time {}

one sig Memory {
	turn: Int -> Time,
	flag: Int -> Int -> Time
}{
	all t: Time {
		one flag[0].t
		one flag[1].t
	}
}

one sig PC {
	proc: Int -> Int -> Time
}{
	all t: Time {
		one proc[0].t
		one proc[1].t
	}
}


fact {
	// 最初はメモリはみんな0
	let t = first {
		Memory.turn.t = 0
		Memory.flag[0].t = 0
		Memory.flag[1].t = 0
		// 最初はプログラムカウンタは0
		PC.proc[0].t = 0
		PC.proc[1].t = 0
 	}
}

pred store(t: Time, target: univ -> Time, value: univ){
	one value
	target.t = value
}

pred must_wait(t: Time, pid: Int){
	let other = (0 + 1) - pid {
		Memory.flag[other].t = 1 // otherがwaitしている
		Memory.turn.t = other // otherが優先権を持っている
	}
}

pred no_change(t: Time, changable: univ -> Time){
	changable.t = changable.(t.prev)
}

pred step(t: Time) {
	// 各時刻でどちらかのプロセスが1命令実行する
	some pid: (0 + 1) {
		let pc = PC.proc[pid].(t.prev),
				nextpc = PC.proc[pid].t,
				other = (0 + 1) - pid
		{

			(pc = 0) => {
				// flag[0] = 1
				store[t, Memory.flag[pid], 1]
				nextpc = 1
				no_change[t, Memory.turn]
			}
			(pc = 1) => {
				// flag[0] = 1
				store[t, Memory.turn, other]
				nextpc = 2
				no_change[t, Memory.flag[pid]]
			}
			(pc = 2) => {
				// while( flag[1] && turn == 1 );
				must_wait[t, pid] => {
					nextpc = 2
				}else{
					nextpc = 3
				}
				no_change[t, Memory.turn]
				no_change[t, Memory.flag[pid]]
			}
			(pc = 3) => {
				// flag[0] = 0
				store[t, Memory.flag[pid], 0]
				nextpc = 0
				no_change[t, Memory.turn]
			}

			// no change
			no_change[t, PC.proc[other]]
			no_change[t, Memory.flag[other]]
		}
	}
}

fact {
	all t: Time - first {
		step[t]
	}
}
run {
	some t: Time {
		PC.proc[0].t = 3
		PC.proc[1].t = 3
	}
} for 20 Time
