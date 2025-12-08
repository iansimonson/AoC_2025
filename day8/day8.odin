package day8

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

    fmt.println("Advent of Code Day 8!")
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

    p1 := part_1(string(data), 1000)
    p2 := part_2(string(data))

    fmt.println("Part 1:", p1)
    fmt.println("Part 2:", p2)
}

usage :: proc() {
    fmt.wprintfln(stderr, "Usage: %s path/to/input.txt", os2.args[0])
}

Point :: [3]int


parse_points :: proc(data: string) -> []Point {
    data := data
    points := make([dynamic]Point, 0, 1000)
    for line in strings.split_lines_iterator(&data) {
        line := line
        point: Point
        coord: int
        for v in strings.split_iterator(&line, ",") {
            value, _ := strconv.parse_int(v)
            point[coord] = value
            coord += 1
        }
        append(&points, point)
    }
    return points[:]
}

Dist :: struct {
    distance: f64,
    p1, p2: int
}

/* Actually we only need half the matrix and some meta data
build_adj_mat :: proc(points: []Point) -> (mat: []Point) {
    mat_width := len(points)
    mat = make([]Point, mat_width * mat_width)
    for p1, i in points {
        for p2, j in points[i+1:] {
            d := p2 - p1
            p2_idx := i + j
            dist := math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
            mat[i * mat_width + p2_idx] = dist
            mat[p2_idx * mat_width + i] = dist
        }
    }
    return
}
*/

make_dists :: proc(points: []Point) -> [dynamic]Dist {
    dists := make([dynamic]Dist, 0, len(points))
    for p1, i in points {
        for p2, j in points[i + 1:] {
            d := p2 - p1
            dist := math.sqrt(f64(d.x * d.x + d.y * d.y + d.z * d.z))
            append(&dists, Dist{dist, i, j+i+1})
        }
    }
    // reverse sort so we can pop easily
    slice.sort_by(dists[:], proc(i, j: Dist) -> bool {
        return i.distance > j.distance
    })

    return dists
}

part_1 :: proc(data: string, to_connect: int) -> int {
    points := parse_points(data)
    defer delete(points)
    dists := make_dists(points)
    defer delete(dists)

    circuit_for_point := make([]int, len(points))
    for i in 0..<len(circuit_for_point) {
        circuit_for_point[i] = i
    }
    circuit_size := make([]int, len(points))
    for &v in circuit_size {
        v = 1
    }
    defer delete(circuit_for_point)
    defer delete(circuit_size)

    for i in 0..<to_connect {
        dist := pop(&dists)
        circuit_p1 := circuit_for_point[dist.p1]
        circuit_p2 := circuit_for_point[dist.p2]
        // already connected
        if circuit_p1 == circuit_p2 { continue }

        c1_size := &circuit_size[circuit_p1]
        c2_size := &circuit_size[circuit_p2]

        if c1_size^ >= c2_size^ {
            c1_size^ += c2_size^
            c2_size^ = 0
            for &c in circuit_for_point {
                if c == circuit_p2 {
                    c = circuit_p1
                }
            }
        } else {
            c2_size^ += c1_size^
            c1_size^ = 0
            for &c in circuit_for_point {
                if c == circuit_p1 {
                    c = circuit_p2
                }
            }
        }

    }

    largest: [3]int
    for c in circuit_size {
        if c > largest.x {
            largest.yz = largest.xy
            largest.x = c
        } else if c > largest.y {
            largest.z = largest.y
            largest.y = c
        } else if c > largest.z {
            largest.z = c
        }
    }

    return largest.x * largest.y * largest.z
}

part_2 :: proc(data: string) -> int {
    points := parse_points(data)
    defer delete(points)
    dists := make_dists(points)
    defer delete(dists)

    circuit_for_point := make([]int, len(points))
    for i in 0..<len(circuit_for_point) {
        circuit_for_point[i] = i
    }
    circuit_size := make([]int, len(points))
    for &v in circuit_size {
        v = 1
    }
    defer delete(circuit_for_point)
    defer delete(circuit_size)

    for {
        dist := pop(&dists)
        circuit_p1 := circuit_for_point[dist.p1]
        circuit_p2 := circuit_for_point[dist.p2]
        // already connected
        if circuit_p1 == circuit_p2 { continue }

        c1_size := &circuit_size[circuit_p1]
        c2_size := &circuit_size[circuit_p2]

        if c1_size^ + c2_size^ == len(points) {
            p1 := points[dist.p1]
            p2 := points[dist.p2]
            return p1.x * p2.x
        }

        if c1_size^ >= c2_size^ {
            c1_size^ += c2_size^
            c2_size^ = 0
            for &c in circuit_for_point {
                if c == circuit_p2 {
                    c = circuit_p1
                }
            }
        } else {
            c2_size^ += c1_size^
            c1_size^ = 0
            for &c in circuit_for_point {
                if c == circuit_p1 {
                    c = circuit_p2
                }
            }
        }

    }


    return 0
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input, 10), 40)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 25272)
}

test_input := `162,817,812
57,618,57
906,360,560
592,479,940
352,342,300
466,668,158
542,29,236
431,825,988
739,650,466
52,470,668
216,146,977
819,987,18
117,168,530
805,96,715
346,949,466
970,615,88
941,993,340
862,61,35
984,92,344
425,690,689`
