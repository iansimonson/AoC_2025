package day2

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

    fmt.println("Advent of Code Day 2!")
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

    s := time.now()

    p1 := part_1(string(data))
    p2 := part_2(string(data))

    e := time.now()

    fmt.println("Time:", time.diff(s, e))
    fmt.println("Part 1:", p1)
    fmt.println("Part 2:", p2)
}

usage :: proc() {
    fmt.wprintfln(stderr, "Usage: %s path/to/input.txt", os2.args[0])
}

part_1 :: proc(data: string) -> int {
    result: int
    ranges, split_err := strings.split(data, ",")
    defer delete(ranges)
    if split_err != nil {
        fmt.wprintfln(stderr, "Could not split string - %#v", split_err)
        return 0
    }

    for range, i in ranges {
        range_result: int
        num_range_results: int
        sep := strings.index_byte(range, '-')
        start, s_ok := strconv.parse_int(range[:sep])
        end, e_ok := strconv.parse_int(strings.trim_right_space(range[sep+1:]))
        if !s_ok || !e_ok {
            fmt.wprintfln(stderr, "Could not parse range %d - %s, s_ok: %v, e_ok: %v", i, range, s_ok, e_ok)
            continue
        }

        start_digits := num_digits(start)
        end_digits := num_digits(end)

        // if there are an odd number of digits and we're not
        // able to add more digits, then there will be no possible double
        // strings of digits
        if start_digits == end_digits && ((start_digits & 1) != 0) do continue


        to_check := start
        if (start_digits & 1) != 0 {
            to_check = next_smallest_possible_p10(to_check)
            start_digits = num_digits(to_check)
        }

        /*fmt.printfln("range %d - %s: start: %d, end: %d, start_digits: %d, end_digits: %d, to_check: %d",
            i, range, start, end, start_digits, end_digits, to_check)*/

        outer: for start_digits <= end_digits {
            half_digits := start_digits / 2
            p10_half_digits := pow_10(half_digits)
            left_value := to_check / p10_half_digits
            right_value := to_check % p10_half_digits

            /*fmt.printfln("range %d - %s: start_digits: %d, half_digits: %d, p10_half: %d, left: %d, right: %d",
                i, range, start_digits, half_digits, p10_half_digits, left_value, right_value)*/

            // just need to make the smallest number larger than current
            // which happens to be left value + 1 and arbitrary right value
            // if right value is less, then just set it to left value effectively
            if left_value < right_value {
                left_value += 1
            }

            // at this point left and right value are the same so just use left
            value := full_number(left_value)
            if value > end {
                break outer
            }
            /*fmt.printfln("range %d - %s found match: %d", i, range, value)*/

            range_result += value
            num_range_results += 1
            for left_value < (p10_half_digits - 1) {
                left_value += 1
                value = full_number(left_value)
                /*fmt.printfln("range %d - %s checking string %d, becomes %d, end %d", i, range, left_value, value, end)*/
                if value > end {
                    break outer
                }
                /*fmt.printfln("range %d - %s found match: %d", i, range, value)*/
                range_result += value
                num_range_results += 1
            }

            to_check = next_smallest_possible_p10(to_check)
            start_digits = num_digits(to_check)
        }

        /*fmt.printfln("range %d - %s added %d matches for %d value", i, range, num_range_results, range_result)*/
        result += range_result
        
    }
    return result
}

part_2 :: proc(data: string) -> int {
    result: int
    ranges, split_err := strings.split(data, ",")
    defer delete(ranges)
    if split_err != nil {
        fmt.wprintfln(stderr, "Could not split string - %#v", split_err)
        return 0
    }
    values: [dynamic]int
    defer delete(values)
    // need the map becuase some IDs can match multiple times e.g. 1111
    matches: map[int]struct{}
    defer delete(matches)

    for range, i in ranges {
        clear(&matches)
        sep := strings.index_byte(range, '-')
        start, s_ok := strconv.parse_int(range[:sep])
        end, e_ok := strconv.parse_int(strings.trim_right_space(range[sep+1:]))
        if !s_ok || !e_ok {
            fmt.wprintfln(stderr, "Could not parse range %d - %s, s_ok: %v, e_ok: %v", i, range, s_ok, e_ok)
            continue
        }

        start_digits := num_digits(start)
        end_digits := num_digits(end)

        to_check := start

        outer: for start_digits <= end_digits {
            split: for split_by := start_digits; split_by >= 2; split_by -= 1 {
                clear(&values)
                if start_digits % split_by != 0 do continue

                split_digits := start_digits / split_by
                p10_split_digits := pow_10(split_digits)
                // fmt.printfln("range %d - %s splitting in %ds %d digits per value %d ceiling", i, range, split_by, split_digits, p10_split_digits)

                split_to_check := to_check

                for split_to_check > 0 {
                    append(&values, split_to_check % p10_split_digits)
                    split_to_check /= p10_split_digits
                }
                // generalized form of left_value + 1 if left_value < right_value
                for &v, i in values[1:] {
                    if v < values[i] {
                        v += 1
                        values[i] = 0
                    }
                }
                left_value := values[len(values) - 1]
                
                // now in same place as before, just cycle through
                value := full_number_nsplit(left_value, split_by)
                // fmt.printfln("range %d - %s split by %d all values = %v, starting with left value %d full value %d", i, range, split_by, values[:], left_value, value)
                if value > end {
                    // fmt.printfln("range %d - %s full value %d greater than end %d", i, range, value, end)
                    continue
                }
                // fmt.printfln("range %d - %s, split_by %d found match: %d", i, range, split_by, value)
                matches[value] = {}
                for left_value < (p10_split_digits - 1) {
                    left_value += 1
                    value = full_number_nsplit(left_value, split_by)
                    if value > end {
                        continue split
                    }
                    // fmt.printfln("range %d - %s, split_by %d found match: %d", i, range, split_by, value)
                    matches[value] = {}
                }
            }

            to_check = next_smallest_possible_part2(to_check)
            start_digits = num_digits(to_check)
            //fmt.printfln("range %d - %s, next checking %d, digits %d", i, range, to_check, start_digits)
        }

        for k, _ in matches {
            //fmt.printfln("range %d - %s. found match %d", i, range, k)
            result += k
        }
    }
    return result
}

num_digits :: proc(value: int) -> int {
    value := value
    result: int
    for value > 0 {
        result += 1
        value /= 10
    }
    return result
}

pow_10 :: proc(power: int) -> int {
    result := 1
    for i in 0..<power {
        result *= 10
    }
    return result
}

// returns the smallest next possible value given a current value
// e.g. 123123 -> 10001000
// because after 6, the next possible number of digits is 8 and
// numbers can't start with a 0
next_smallest_possible_p10 :: proc(value: int) -> int {
    value := value
    cur_p10 := num_digits(value)
    if (cur_p10 & 1) != 0 {
        value *= 10
        cur_p10 += 1
    } else {
        value *= 100
        cur_p10 += 2
    }

    cur_p10_half := cur_p10 / 2
    result := 1
    for i in 0..<cur_p10_half {
        result *= 10
    }

    result += 1
    for i in 0..<(cur_p10_half - 1) {
        result *= 10
    }
    return result
}

// unlike in p1, we could possibly have odd number
// of digits here. this would also work for part 1
// but I wrote the more complicates/specific version first
next_smallest_possible_part2 :: proc(value: int) -> int {
    value := value
    cur_p10 := num_digits(value)
    return pow_10(cur_p10)
}

// this only works for part 1 since it's basically full_number_nsplit
// below but split_by is 2. However I wrote it first so I'm leaving it as-is
full_number :: proc(num: int) -> int {
    digits := num_digits(num)
    shift := pow_10(digits)
    return num * shift + num
}

// the more gneeralized version of full_number
full_number_nsplit :: proc(num, split_by: int) -> int {
    digits := num_digits(num)
    shift := pow_10(digits)
    result := num
    split_by := split_by
    for split_by > 1 {
        result = (result * shift) + num
        split_by -= 1
    }
    return result
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 1227775554)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 4174379265)
}

test_input := `11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124`

