package day11

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os/os2"
import "core:io"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

stderr: io.Stream

main :: proc() {
    stderr = os2.to_writer(os2.stderr)

    fmt.println("Advent of Code Day 11!")
    fmt.println("=====================")

    if len(os2.args) < 2 {
        fmt.wprintln(stderr, "Error - no file provided")
        usage()
        os2.exit(1)
    }

    data, file_err := os2.read_entire_file_from_path(os2.args[1], context.allocator)
    if file_err != nil {
        fmt.wprintfln(stderr, "Error reading %s - %#v", os2.args[1], file_err)
        usage()
        os2.exit(1)
    }

    p1 := part_1(string(data))
    p2 := part_2(string(data))

    fmt.println("Part 1:", p1)
    fmt.println("Part 2:", p2)
}

usage :: proc() {
    fmt.wprintfln(stderr, "Usage: %s path/to/input.txt", os2.args[0])
}

Machine :: distinct u32
Adj_List :: map[Machine][dynamic]Machine
parse_adj_list :: proc(data: string) ->  Adj_List {
    data := data
    result := make(Adj_List)

    buffer: [4]u8
    for line in strings.split_lines_iterator(&data) {
        line := line
        colon := strings.index_byte(line, ':')
        assert(colon == 3)
        copy(buffer[:], line[:colon])
        this_machine := transmute(Machine) buffer
        rest := line[colon + 2:]
        adjacent := make([dynamic]Machine)
        for machine in strings.split_by_byte_iterator(&rest, ' ') {
            buffer = 0
            assert(len(machine) <= 4)
            copy(buffer[:], machine)
            m := transmute(Machine) buffer
            append(&adjacent, m)
        }
        result[this_machine] = adjacent
    }

    return result
}

part_1 :: proc(data: string) -> int {
    start_buf, goal_buf: [4]u8
    copy(start_buf[:], "you")
    copy(goal_buf[:], "out")
    start, goal := transmute(Machine) start_buf, transmute(Machine) goal_buf
    
    adj_list := parse_adj_list(data)
    defer {
        for k, &v in adj_list {
            delete(v)
        }
        delete(adj_list)
    }
    // total paths from M to OUT
    paths := make(map[Machine]int)
    defer delete(paths)

    paths[goal] = 1
    // don't even need goal b/c it's always in paths
    find_paths :: proc(cur: Machine, adj_list: Adj_List, paths: ^map[Machine]int) -> int {
        assert(cur not_in paths)

        our_paths: int
        adjacent := adj_list[cur]
        for neighbor in adjacent {
            if neighbor in paths {
                our_paths += paths[neighbor]
            } else {
                our_paths += find_paths(neighbor, adj_list, paths)
            }
        }
        paths[cur] = our_paths
        return our_paths
    }

    return find_paths(start, adj_list, &paths)
}

FOUND_DAC: u32 = 1 << 30
FOUND_FFT: u32 = 1 << 31
MASK: u32 = FOUND_DAC | FOUND_FFT
DAC: Machine
FFT: Machine

part_2 :: proc(data: string) -> int {
    start_buf, goal_buf: [4]u8
    copy(start_buf[:], "svr")
    copy(goal_buf[:], "out")
    start, goal := transmute(Machine) start_buf, transmute(Machine) goal_buf

    copy(start_buf[:], "dac")
    copy(goal_buf[:], "fft")
    DAC = transmute(Machine) start_buf
    FFT = transmute(Machine) goal_buf
    
    adj_list := parse_adj_list(data)
    defer {
        for k, &v in adj_list {
            delete(v)
        }
        delete(adj_list)
    }

    goal = Machine(u32(goal) | MASK)

    // total paths from M to OUT
    paths := make(map[Machine]int)
    defer delete(paths)
    paths[goal] = 1

    find_paths :: proc(cur: Machine, adj_list: Adj_List, paths: ^map[Machine]int) -> int {
        raw_cur := Machine(u32(cur) & ~MASK)
        cur_mask := u32(cur) & MASK
        assert(cur not_in paths)

        our_paths: int
        adjacent := adj_list[raw_cur]
        for neighbor in adjacent {
            real_neighbor := Machine(u32(neighbor) | cur_mask)
            if neighbor == DAC {
                real_neighbor = Machine(u32(real_neighbor) | FOUND_DAC)
            } else if neighbor == FFT {
                real_neighbor = Machine(u32(real_neighbor) | FOUND_FFT)
            }

            if real_neighbor in paths {
                our_paths += paths[real_neighbor]
            } else {
                our_paths += find_paths(real_neighbor, adj_list, paths)
            }
        }
        paths[cur] = our_paths
        return our_paths
    }

    return find_paths(start, adj_list, &paths)
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 5)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(t2_input), 2)
}

test_input := `aaa: you hhh
you: bbb ccc
bbb: ddd eee
ccc: ddd eee fff
ddd: ggg
eee: out
fff: out
ggg: out
hhh: ccc fff iii
iii: out`

t2_input := `svr: aaa bbb
aaa: fft
fft: ccc
bbb: tty
tty: ccc
ccc: ddd eee
ddd: hub
hub: fff
eee: dac
dac: fff
fff: ggg hhh
ggg: out
hhh: out`