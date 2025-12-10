package day10

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

    fmt.println("Advent of Code Day 10!")
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
    fmt.println("part 1 done")
    p2 := part_2(string(data))

    fmt.println("Part 1:", p1)
    fmt.println("Part 2:", p2)
}

usage :: proc() {
    fmt.wprintfln(stderr, "Usage: %s path/to/input.txt", os2.args[0])
}

Lights :: bit_set[0..=9]

parse_buttons :: proc(raw: string) -> [dynamic]Lights {
    raw := raw
    buttons := make([dynamic]Lights)
    for len(raw) > 0 {
        next := strings.index_byte(raw, '(')
        if next == -1 { break }
        end := strings.index_byte(raw, ')')
        button_raw := raw[next+1:end]
        button: Lights
        for v_str in strings.split_iterator(&button_raw, ",") {
            v, _ := strconv.parse_int(v_str)
            button += Lights{v}
        }
        append(&buttons, button)
        raw = raw[end + 1:]
    }
    return buttons
}

part_1 :: proc(data: string) -> int {
    result: int
    lines := strings.split_lines(data)
    for line, l_no in lines {
        if len(line) == 0 { continue }
        start, goal: Lights
        end := strings.index_byte(line, ']')
        
        for l, i in line[1:end] {
            if l == '#' {
                goal += {i}
            }
        }
        joltage_begin := strings.index_byte(line, '{')
        buttons := parse_buttons(line[end + 1:joltage_begin])
        cache := make(map[Lights]int)

        find_goal :: proc(cur, goal: Lights, cur_presses: int, buttons: []Lights, cache: ^map[Lights]int) -> (int, bool) {
            // see if we got here faster
            if cur == goal {
                cached, exists := cache[goal]
                if !exists {
                    cache[goal] = cur_presses
                    return cur_presses, true
                } else if cur_presses < cached {
                    cache[goal] = cur_presses
                    return cur_presses, true
                } else {
                    return cached, false
                }
            } else if goal in cache && cache[goal] <= cur_presses { // if we reached goal already another way, exit here
                return max(int), false
            }

            if cur in cache && cache[cur] < cur_presses { // we're back to where we were before
                return max(int), false
            }

            cache[cur] = cur_presses

            least_presses := max(int)
            found_here: bool
            for button in buttons {
                next := cur ~ button
                min_presses, found := find_goal(next, goal, cur_presses + 1, buttons, cache)
                if found {
                    least_presses = min(least_presses, min_presses)
                    found_here = true
                }
            }

            return least_presses, found_here
        }

        presses, found := find_goal(start, goal, 0, buttons[:], &cache)
        if !found {
            fmt.printfln("%d - %s. somehow did not find num presses", l_no, line)
        } else {
            result += presses
        }
    }

    return result
}

parse_joltages :: proc(raw: string) -> State {
    assert(raw[0] == '{', "could not parse joltage")
    end := strings.index_byte(raw, '}')
    if end == -1 { return {} }
    joltages: State
    j_str := raw[1:end]
    v_idx := 0
    for v_str in strings.split_iterator(&j_str, ",") {
        joltage, _ := strconv.parse_int(v_str)
        joltages.joltages[v_idx] = joltage
        v_idx += 1
    }
    return joltages
}

State :: struct {
    joltages: [10]int,
    num_joltages: int,
}

part_2 :: proc(data: string) -> int {
    result: int
    lines := strings.split_lines(data)
    for line, l_no in lines {
        if len(line) == 0 { continue }
        start, goal: Lights
        end := strings.index_byte(line, ']')

        joltage_begin := strings.index_byte(line, '{')
        buttons := parse_buttons(line[end + 1:joltage_begin])
        joltages := parse_joltages(line[joltage_begin:])
        cur_joltages := State{0, joltages.num_joltages}
        cache := make(map[State]int)

        find_goal :: proc(cur, goal: State, cur_presses: int, buttons: []Lights, cache: ^map[State]int) -> (int, bool) {
            if cur == goal {
                cached, exists := cache[goal]
                if !exists {
                    cache[goal] = cur_presses
                    return cur_presses, true
                } else if cur_presses < cached {
                    cache[goal] = cur_presses
                    return cur_presses, true
                } else {
                    return cached, false
                }
            } else if goal in cache && cache[goal] <= cur_presses { // if we reached goal already another way, exit here
                return max(int), false
            }

            if cur in cache && cache[cur] < cur_presses { // we're back to where we were before
                return max(int), false
            }

            cache[cur] = cur_presses

            m := max(int)
            found_here: bool
            next := cur
            outer: for button in buttons {
                for b in button {
                    next.joltages[b] += 1
                }
                defer for b in button {
                    next.joltages[b] -= 1
                }

                for joltage, i in next.joltages {
                    // can never go down in joltage
                    if joltage > goal.joltages[i] { continue outer }
                }

                presses, found := find_goal(next, goal, cur_presses + 1, buttons, cache)
                if found {
                    m = min(m, presses)
                    found_here = true
                }
            }

            return m, found_here
        }

        presses, _ := find_goal(cur_joltages, joltages, 0, buttons[:], &cache)
        result += presses
    }

    return result
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 1234)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 1234)
}

test_input := `[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}`
