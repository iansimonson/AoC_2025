package day9

import "core:fmt"
import "core:math"
import "core:math/linalg"
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

    fmt.println("Advent of Code Day 9!")
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

part_1 :: proc(data: string) -> int {
    data := data
    largest: int
    points := make([dynamic][2]int, 0, 100)
    for line in strings.split_lines_iterator(&data) {
        comma := strings.index_byte(line, ',')
        p_x, _ := strconv.parse_int(line[:comma])
        p_y, _ := strconv.parse_int(line[comma+1:])
        point := [2]int{p_x, p_y}
        for p2 in points {
            // inclusive ranges
            d := linalg.abs(p2 - point) + [2]int{1, 1}
            area := d.x * d.y
            if area > largest {
                largest = area
            }
        }
        append(&points, point)
    }

    return largest
}

Point :: [2]int
Line_Seg :: [2]Point

is_right_turn :: proc(pt, prv, nxt: Point) -> bool {
    l1, l2 := pt - prv, nxt - pt
    if l1.x == 0 {
        return (l1.y > 0 && l2.x > 0) || (l1.y < 0 && l2.x < 0)
    } else if l1.y == 0 {
        return (l1.x > 0 && l2.y < 0) || (l1.x < 0 && l2.y > 0)
    } else {
        fmt.wprintfln(stderr, "ERROR: point %v with lines %v, %v don't turn", pt, l1, l2)
        return false
    }
}

intersects_non_overlapping :: proc(l1, l2: Line_Seg) -> bool {
    l1_horiz := (l1.y - l1.x).y == 0
    l2_horiz := (l2.y - l2.x).y == 0

    if l1_horiz && !l2_horiz {
        l1_x1, l1_x2 := l1[0].x, l1[1].x
        l1_x1, l1_x2 = min(l1_x1, l1_x2), max(l1_x1, l1_x2) // make canonical
        l1_y := l1[0].y

        l2_x := l2[0].x
        l2_y1, l2_y2 := l2[0].y, l2[1].y
        l2_y1, l2_y2 = min(l2_y1, l2_y2), max(l2_y1, l2_y2) // make canonical

        return (l1_x1 < l2_x && l1_x2 > l2_x) && (l1_y > l2_y1 && l1_y < l2_y2)
    } else if !l1_horiz && l2_horiz {
        l1_y1, l1_y2 := l1[0].y, l1[1].y
        l1_y1, l1_y2 = min(l1_y1, l1_y2), max(l1_y1, l1_y2) // make canonical
        l1_x := l1[0].x

        l2_y := l2[0].y
        l2_x1, l2_x2 := l2[0].x, l2[1].x
        l2_x1, l2_x2 = min(l2_x1, l2_x2), max(l2_x1, l2_x2) // make canonical

        return (l1_y1 < l2_y && l1_y2 > l2_y) && (l1_x > l2_x1 && l1_x < l2_x2)
    }

    return false
}

// ignore the fact it says x1, x2 - this works with ys also
overlapping :: proc(l1, l2, p: int) -> bool {
    l1, l2 := min(l1, l2), max(l1, l2)
    return l1 < p && p < l2
}

leaving_object :: proc(r1, r2, connected1, connected2: Line_Seg, right_turn: bool) -> bool {
    r1_dir := r1[1] - r1[0]
    r2_dir := r2[1] - r2[0]

    c1_dir := connected1[1] - connected1[0]
    c2_dir := connected2[1] - connected2[0]

    if right_turn {
        return (linalg.dot(r1_dir, c1_dir) + linalg.dot(r1_dir, c2_dir) < 0) &&
                (linalg.dot(r2_dir, c1_dir) + linalg.dot(r2_dir, c2_dir) < 0)
    } else {
        return (linalg.dot(r1_dir, c1_dir) + linalg.dot(r1_dir, c2_dir) > 0) &&
                (linalg.dot(r2_dir, c1_dir) + linalg.dot(r2_dir, c2_dir) > 0)
    }
}

// returns true if box is within the overall shape
check_rays :: proc(c1_idx, c2_idx: int, points: []Point, right_turns: []bool, line_segs: []Line_Seg) -> bool {
    assert(len(points) == len(right_turns))
    assert(len(points) == len(line_segs))

    c1, c2 := points[c1_idx], points[c2_idx]
    opp_pt1, opp_pt2 := Point{c1.x, c2.y}, Point{c2.x, c1.y}

    l1 := Line_Seg{c1, opp_pt1} // always vertical line
    l2 := Line_Seg{c1, opp_pt2} // always horizontal line
    prv_l := Line_Seg{points[(c1_idx - 1) %% len(points)], c1}
    nxt_l := Line_Seg{points[(c1_idx + 1) %% len(points)], c1}
    if leaving_object(l1, l2, prv_l, nxt_l, right_turns[c1_idx]) { return false }
    
    l3 := Line_Seg{c2, opp_pt1} // always horizontal
    l4 := Line_Seg{c2, opp_pt2} // always vertical
    prv2_l := Line_Seg{points[(c2_idx - 1) %% len(points)], c2}
    nxt2_l := Line_Seg{points[(c2_idx + 1) %% len(points)], c2}
    if leaving_object(l3, l4, prv2_l, nxt2_l, right_turns[c2_idx]) { return false }


    for line_seg in line_segs {
        // non-overlapping becuase it's ok to end on the line segment
        if intersects_non_overlapping(l1, line_seg) || intersects_non_overlapping(l2, line_seg) { return false }
        else if intersects_non_overlapping(l3, line_seg) || intersects_non_overlapping(l4, line_seg) { return false }
    }

    for point, i in points {
        if point == c1 || point == opp_pt1 || point == c2 || point == opp_pt2 { continue }
        
        if l1[0].x == point.x && overlapping(l1[0].y, l1[1].y, point.y) && !right_turns[i] { return false }
        else if l2[0].y == point.y && overlapping(l2[0].x, l2[1].x, point.x) && !right_turns[i] { return false }
        else if l3[0].y == point.y && overlapping(l3[0].x, l3[1].x, point.x) && !right_turns[i] { return false }
        else if l4[0].x == point.x && overlapping(l4[0].y, l4[1].y, point.y) && !right_turns[i] { return false }
    }

    return true
}

part_2 :: proc(data: string) -> int {
    data := data
    points := make([dynamic]Point, 0, 100)
    largest: int

    for line in strings.split_lines_iterator(&data) {
        comma := strings.index_byte(line, ',')
        p_x, _ := strconv.parse_int(line[:comma])
        p_y, _ := strconv.parse_int(line[comma+1:])
        point := Point{p_x, p_y}
        append(&points, point)
    }

    right_turns := make([]bool, len(points))
    line_segs := make([]Line_Seg, len(points))
    for p, i in points {
        right_turns[i] = is_right_turn(p, points[(i - 1) %% len(points)], points[(i + 1) %% len(points)])
        line_segs[i] = Line_Seg{points[(i - 1) %% len(points)], p}
    }

    for p1, i in points {
        for p2, j in points[i+1:] {
            if check_rays(i, j + (i + 1), points[:], right_turns, line_segs) {
                // inclusive ranges
                d := linalg.abs(p2 - p1) + [2]int{1, 1}
                area := d.x * d.y
                // fmt.printfln("points (%v, %v) seem ok - area %d", p1, p2, area)
                if area > largest {
                    largest = area
                }
            }
        }
    }

    return largest
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 50)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 24)
}

@(test)
part_2_test_2 :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(t2), 33)
}

test_input := `7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3`

t2 := `1,0
3,0
3,5
16,5
16,0
18,0
18,9
13,9
13,7
6,7
6,9
1,9`