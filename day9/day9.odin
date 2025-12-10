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
import rl "vendor:raylib"
import "core:c"

stderr: io.Stream

USE_RAYLIB :: #config(USE_RAYLIB, false)

main :: proc() {
    when USE_RAYLIB {
        rl.InitWindow(1080, 920, "woo")
        defer rl.CloseWindow()
    }
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

    s := time.now()
    p1 := part_1(string(data))
    pe := time.now()
    p2 := part_2(string(data))
    e := time.now()

    fmt.printfln("Timing: %v, %v", time.diff(s, pe), time.diff(pe, e))

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

// returns true if box is within the overall shape
check_rays :: proc(c1_idx, c2_idx: int, points: []Point, line_segs: []Line_Seg) -> bool {
    assert(len(points) == len(line_segs))

    c1, c2 := points[c1_idx], points[c2_idx]

    bounds := [2]Point{{min(c1.x, c2.x), min(c1.y, c2.y)}, {max(c1.x, c2.x), max(c1.y, c2.y)}}
    bounds_dir := bounds[1] - bounds[0]

    // first check, are there any points (vertices) on the interor of the square?
    // if so then this is an invalid square, no need to do other checks
    for p in points {
        if p == c1 || p == c2 { continue }
        // p is within the bounding box (and not on the perimeter line)
        if bounds[0].x < p.x && p.x < bounds[1].x && bounds[0].y < p.y && p.y < bounds[1].y { 
            return false 
        }
    }

    
    horizontal_rays := Point{bounds[0].x /* + (bounds[1].x - bounds[0].x) / 2*/, bounds[0].y}
    vert_rays := Point{bounds[0].x, bounds[0].y /*+ (bounds[1].y - bounds[0].y) / 2*/}

    intersects_horiz: int
    intersects_verts: int
    {
        x := min(bounds[0].x + 1, bounds[1].x)
        intersects_horiz = 0
        for line_seg in line_segs {
            ls_dir := line_seg[1] - line_seg[0]
            if ls_dir.y != 0 { continue } // checking horizontal lines only
            if line_seg[0].y > bounds[0].y && line_seg[0].x < x && line_seg[1].x > x {
                intersects_horiz += 1
            }
        }
        if intersects_horiz > 1 { return false }
    }

    {
        y := min(bounds[0].y + 1, bounds[1].y)
        intersects_verts = 0
        for line_seg in line_segs {
            ls_dir := line_seg[1] - line_seg[0]
            if ls_dir.x != 0 { continue } // checking vertical lines only
            if line_seg[0].x > bounds[0].x && line_seg[0].y < y && line_seg[1].y > y {
                intersects_verts += 1
            }
        }
        if intersects_verts > 1 { return false }
    }

    // remaining edge case, what if it's all on a single line and we need to detect it's outside...
    // this is probably fine to ignore because the area we're looking for is quite large
    // hah, it is not fine to ignore this case, my current answer is wrong despite all examples passing

    return true
}

part_2 :: proc(data: string) -> int {
    data := data
    points := make([dynamic]Point, 0, 100)
    defer delete(points)
    largest: int

    for line in strings.split_lines_iterator(&data) {
        comma := strings.index_byte(line, ',')
        p_x, _ := strconv.parse_int(line[:comma])
        p_y, _ := strconv.parse_int(line[comma+1:])
        point := Point{p_x, p_y}
        append(&points, point)
    }

    // line segments are all set up so the closer point to
    // (0, 0) is first and the further point is second
    // since all lines are horizontal or vertical this is just based
    // on the relevant x or y coord
    line_segs := make([]Line_Seg, len(points))
    defer delete(line_segs)
    for p, i in points {
        p1 := p
        p2 := points[(i - 1) %% len(points)]
        dv := p2 - p1
        if dv.x == 0 { // vertical line
            p1, p2 = Point{p1.x, min(p1.y, p2.y)}, Point{p1.x, max(p1.y, p2.y)}
            line_segs[i] = Line_Seg{p1, p2}
        } else if dv.y == 0 {
            p1, p2 = Point{min(p1.x, p2.x), p1.y}, Point{max(p1.x, p2.x), p1.y}
            line_segs[i] = Line_Seg{p1, p2}
        } else {
            assert(false, "unable to make line segment")
        }
    }

    largest_x: int
    largest_y: int
    for p in points {
        if p.x > largest_x {
            largest_x = p.x
        }
        if p.y > largest_y {
            largest_y = p.y
        }
    }


    lp1, lp2: Point

    for p1, i in points {
        for p2, j in points[i+1:] {
            if check_rays(i, j + (i + 1), points[:], line_segs) {
                // inclusive ranges
                d := linalg.abs(p2 - p1) + [2]int{1, 1}
                area := d.x * d.y
                if area > largest {
                    lp1, lp2 = p1, p2
                    largest = area
                }
            }
        }
    }

    when !ODIN_TEST && USE_RAYLIB {
        for {
            rl.BeginDrawing()
            for l in line_segs {
                rl.DrawLine(c.int(f64(l[0].x)/f64(largest_x) * 1080), c.int(f64(l[0].y)/f64(largest_y)*920), c.int(f64(l[1].x)/f64(largest_x) * 1080), c.int(f64(l[1].y)/f64(largest_y) * 920), rl.GREEN)
            }
            for p in points {
                rl.DrawCircle(c.int(f64(p.x)/f64(largest_x)*1080), c.int(f64(p.y)/f64(largest_y)*920), 1, rl.RED)
            }
            rl.DrawCircle(c.int(f64(lp1.x)/f64(largest_x)*1080), c.int(f64(lp1.y)/f64(largest_y)*920), 5, rl.BLUE)
            rl.DrawCircle(c.int(f64(lp2.x)/f64(largest_x)*1080), c.int(f64(lp2.y)/f64(largest_y)*920), 5, rl.WHITE)
            d := linalg.abs(lp2 - lp1) + [2]int{1, 1}
            area := d.x * d.y
            fmt.println(lp1, lp2, area)
            rl.EndDrawing()
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

@(test)
part_2_test_3 :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(t3), 24)
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

t3 := `7,1
11,1
11,7
9,7
9,5
6,5
6,7
5,7
5,5
2,5
2,3
7,3`