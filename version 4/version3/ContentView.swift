//
//  ContentView.swift
//  version3
//
//  Created by Anna Finlay on 1/31/25.
//

import SwiftUI
import Combine




var num_rows: Int = 9 // set in stone for now
var num_cols: Int = 8 // just go w it
var num_bombs: Int = 12 // 4 bombs on a grid of 25
var num_flagged: Int = 0 // starts off with 0




let colorDict: [Int: Color] = [
    0: Color(UIColor(named: "0") ?? UIColor.white),
    1: Color(UIColor(named: "1") ?? UIColor.white),
    2: Color(UIColor(named: "2") ?? UIColor.white),
    3: Color(UIColor(named: "3") ?? UIColor.white),
    4: Color(UIColor(named: "4") ?? UIColor.white),
    5: Color(UIColor(named: "5") ?? UIColor.white),
    6: Color(UIColor(named: "6") ?? UIColor.white),
    7: Color(UIColor(named: "7") ?? UIColor.white),
    8: Color(UIColor(named: "8") ?? UIColor.white)
]


//==========================================


struct ContentView: View {
    
    //var matrix: [[Int]] = []
    //@State public var buttons: [[ButtonState]] = []
    @State private var buttons: [[ButtonState]] = Array(repeating: Array(repeating: ButtonState(color: .gray, text: "?", int: -1, bool: false, flag: false), count: num_cols), count: num_rows)
    

    @State private var gameOver = false
    // Flag to check if the game is over
       //this is EXPLICITLY for a win game over condition
    @State private var gameCease = false
    // activates upon a loss condition
    @State private var tilesClicked = 0
    @State private var rightClicked = false // To track if right-click has occurred
    @State private var ng = false // To track if guessless mode is active?
    @State public var showInputFields = true
    @State public var cleanGame = true
    
    //timer stuff//
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State private var cancellable: Cancellable? = nil
    @State private var timeElapsed: Double = 0.0
    @State private var timerRunning: Bool = false
    @State public var matrix: [[Int]] = []
    @State public var matrix_copy: [[Int]] = []
    @State public var borders: [[Int]] = []
    @State public var flags: [[Int]] = []
    @State public var bestScore: String = "NA"
    @State public var bestScoreDouble: Double = 1000000.0
    /////////////////////////

    
    func initializeButtons() {
        buttons = Array(repeating: Array(repeating: ButtonState(color: .gray, text: "", int: -1, bool: false, flag: false), count: 8), count: 9)
    }
    var body: some View {
        ZStack { // this one has two things: restart and button grid.
            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.white]), startPoint: .top, endPoint: .center)
                    .edgesIgnoringSafeArea(.all) // Make sure the gradient covers the entire screen
                    .edgesIgnoringSafeArea(.all) // Make sure the gradient covers the entire screen
            VStack(spacing: 10) {
                Text("Minesweeper")
                    .font(.custom("AvenirNext-Bold", size: 40)) // Custom font (use any font you like)
                    .foregroundColor(.blue) // Text color
                    .bold() // Make the text bold
                    .shadow(radius: 10) // Optional: Add a shadow effect for some coolness
                    .frame(maxWidth: .infinity, alignment: .center) // Center the text
                

                .padding(25)
                Text(String(format: "Personal Best: %@           Time: %.1f", bestScore, timeElapsed))
                HStack(spacing: 20) {
                    Button(action: {
                        ng = !ng
                    }) {
                        Text(" NG ")
                            .padding() // Add padding for spacing inside the button
                            .background(ng ? Color.red : Color.clear)
                            .foregroundColor(.blue) // Text color is blue
                            .cornerRadius(8) // Rounded corners
                            .overlay( // Add border around the button
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 2) // Outline with blue color and a width of 2
                            )
                            .shadow(radius: 5) // Optional: Add a shadow for a more elevated look
                    }
                    Button(action: {
                        restart(a: 100, b: 100)
                    }) {
                        Text("Restart")
                            .padding() // Add padding for spacing inside the button
                            .background(Color.clear) // Transparent background
                            .foregroundColor(.blue) // Text color is blue
                            .cornerRadius(8) // Rounded corners
                            .overlay( // Add border around the button
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 2) // Outline with blue color and a width of 2
                            )
                            .shadow(radius: 5) // Optional: Add a shadow for a more elevated look
                    }
                    Button(action: {
                        restart(a: 200, b: 200)
                    }) {
                        Text("Hint")
                            .padding() // Add padding for spacing inside the button
                            .background(Color.clear) // Transparent background
                            .foregroundColor(.blue) // Text color is blue
                            .cornerRadius(8) // Rounded corners
                            .overlay( // Add border around the button
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 2) // Outline with blue color and a width of 2
                            )
                            .shadow(radius: 5) // Optional: Add a shadow for a more elevated look
                    }
                    
                }
                .onReceive(timer) { _ in
                    if timerRunning {
                        timeElapsed += 0.1
                    }
                }
                
                VStack(spacing: 0) { // this one has the grid of buttons on it, each element is a row
                ForEach(0..<num_rows) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<num_cols) { col in
                            Button(action: {
                                if !rightClicked {
                                    if (cleanGame == true) {
                                        restart(a: row, b: col)
                                        cleanGame = false
                                        explore(row: row, col: col)
                                    }
                                    if (buttons[row][col].color == Color.gray) {
                                        explore(row: row, col: col)
                                    }else {
                                        var adjacent_flags = 0
                                        for adj_r in row-1..<row+2 {
                                            for adj_c in col-1..<col+2 {
                                                if (adj_r < num_rows && adj_r >= 0){
                                                    if (adj_c < num_cols && adj_c >= 0){
                                                        if(buttons[adj_r][adj_c].flag == true){
                                                            adjacent_flags += 1
                                                        }
                                                    }
                                                }
                                                
                                            }
                                        }
                                        if (adjacent_flags == buttons[row][col].int){
                                            for adj_r in row-1..<row+2 {
                                                for adj_c in col-1..<col+2 {
                                                    if (adj_r < num_rows && adj_r >= 0){
                                                        if (adj_c < num_cols && adj_c >= 0){
                                                            if (buttons[adj_r][adj_c].color == Color.gray){
                                                                explore(row: adj_r, col: adj_c)
                                                            }
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                        
                                }else{ // the case of flag being active
                                   // if (buttons[row][col].color == Color.gray){ // can only flag uncovered tiles
                                    flag(row: row, col: col)
                                    //}
                                    
                                }
                            }) {
                                Text(buttons[row][col].text)
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .frame(width: 35, height: 35)
                                    .background(buttons[row][col].color)
                                    .cornerRadius(0)
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                    .opacity((gameOver || gameCease) ? 0.4 : 1)
                                    .brightness(0.2)
                                    //.shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5) // Dark shadow on the bottom right
                                    //.shadow(color: Color.white.opacity(0.4), radius: 10, x: -5, y: -5) // Light shadow on the top left
                                    
                                // 0.4 opacity when game is over
                            }
                            .disabled(gameOver)  // Disable the buttons if game is over
                            .disabled(gameCease)  // Disable the buttons if game is over (another condition)
                        }
                    }
                }
            }
                Button(action: {
                    rightClicked = !rightClicked
                }) {
                    Text("Flag")
                        .padding() // Add padding for spacing inside the button
                        .background(rightClicked ? Color.yellow : Color.white) // Set background color based on the state
                        .foregroundColor(Color.blue) // Set text color based on the state
                        .cornerRadius(8) // Rounded corners to make it look more like a button
                        .overlay( // Add border around the button
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2) // Outline with blue color and a width of 2
                        )
                        .shadow(radius: 5) // Optional: Add a shadow for a more elevated look
                }
                //Text(output)
            }
            .padding()

            // Show "Game Over" text when all tiles are clicked
            if gameOver {
                Text("Win")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 5, x: 0, y: 0)  // Black shadow (outline effect)
                    .opacity(1)
                    .scaleEffect(gameOver ? 1 : 0.8)
                    .animation(.easeIn(duration: 1), value: gameOver)
                //???
            }

            if gameCease {
                Text("Loss")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 5, x: 0, y: 0)  // Black shadow (outline effect)
                    .opacity(1)
                    .scaleEffect(gameCease ? 1 : 0.8)
                    .animation(.easeIn(duration: 1), value: gameCease)
                //???
            }
        }
        .onAppear {
            initializeButtons() // Initialize buttons when the view appears
        }
        .onChange(of: tilesClicked) { newValue in
            // Check if all tiles have been clicked

            for vstack_of_buttons in buttons{
                for a_b in vstack_of_buttons{ //a_button
                    if (a_b.color == Color.gray && a_b.bool == false) {
                        gameOver = false;
                        return;
                    }
                }
            }
            gameOver = true;
            timerRunning = false
            if timeElapsed < bestScoreDouble {
                bestScoreDouble = timeElapsed;
                bestScore = "\(String(format: "%.1f", bestScoreDouble))"
                print(bestScore)
            }
        }
    }
    func resetGameGrid() {
        // Reinitialize the grid with the new dimensions
        buttons = Array(repeating: Array(repeating: ButtonState(color: .gray, text: "?", int: -1, bool: false, flag: false), count: num_cols), count: num_rows)
        restart(a: 100, b: 100)
    }

    
    func restart(a:Int, b:Int) {
        if(a == 200 && b == 200){
            //var help_m_copy = matrix_copy
            borders = Array(repeating: Array(repeating: 0, count: num_cols), count: num_rows)
            flags = Array(repeating: Array(repeating: 0, count: num_cols), count: num_rows)

            //                          1: flipped
            //                          0: unflipped
            //                          -1: flag
            
            for a_row in 0...num_rows - 1{
                for a_col in 0...num_cols - 1{
                    //matrix_copy[a_row][a_col] = buttons[a_row][a_col].int
                    if (buttons[a_row][a_col].flag == true){
                        flags[a_row][a_col] = 1
                        borders[a_row][a_col] = -1
                    } else {
                        if (buttons[a_row][a_col].color != .gray){
                            borders[a_row][a_col] = 1
                        }
                    }
                    
                }
            }
            var add_time = true
            if !(naked_single_flagger(used_as_helper: true)){
                add_time = find_grouping_constraints(used_as_helper: true)
            }
            if (add_time){
                timeElapsed += 10.0
            }
            return;
        }
        cleanGame = true;
        gameOver = false;
        gameCease = false;
        num_flagged = 0;
        for c in 0..<num_cols {
            for r in 0..<num_rows {
                buttons[r][c].color = Color.gray;
                buttons[r][c].text = " ";
                buttons[r][c].bool = false;
                buttons[r][c].int = 0
                buttons[r][c].flag = false
                
            }
        }
        if (a == 100 && b == 100){
            timeElapsed = 0.0;
            timerRunning = false;
            return;
        }
        if (num_bombs >= (num_cols)*(num_rows) - 9){
            for c in 0..<num_cols {
                for r in 0..<num_rows {
                    buttons[r][c].bool = true
                    buttons[r][c].int = -1
                }
            }
        return  // safety so it wont try to put bombs infinite times
        }//if it has a reasonable number of bombs, actually execute...
        

        var num_bombs_implemented = 0
        while num_bombs_implemented < num_bombs {
            
            let c = Int(arc4random_uniform(UInt32(num_cols)));
            let r = Int(arc4random_uniform(UInt32(num_rows)));
            
            if (buttons[r][c].bool == false) {
                //if (a != r || b != c){
                if (abs(a - r) >= 2 || abs(b - c) >= 2) {
                    num_bombs_implemented += 1
                    buttons[r][c].bool = true;
                    buttons[r][c].int = -1 // put the bomb in place
                                       // THEN mark surrounding nums
                    for adj_r in r-1..<r+2 {
                        for adj_c in c-1..<c+2 {
                            if adj_r >= 0 && adj_c >= 0 {
                                
                                if (adj_r < num_rows && adj_c < num_cols){
                                    if (buttons[adj_r][adj_c].bool == false ){
                                        buttons[adj_r][adj_c].int += 1
                                    }
                                }
                            }
                        }
                    }
                }
                
                //num_bombs_implemented += 1
            } // standardizes
        }/*
        var matrix = ""
        for r in 0..<num_rows {
            for c in 0..<num_cols {
                matrix.append(String(buttons[r][c].int))
            }*/
        var matrix: [[Int]] = []
        for r in 0..<num_rows {
            var row: [Int] = []
            for c in 0..<num_cols {
                row.append(buttons[r][c].int)
            }
            matrix.append(row)
        }//////////////////////////////////////////////////////////////////////////
        
        //stuff()
        if (ng){
            if (matrix[0][2] == -1 && matrix[1][2] == -1 ){
                if (matrix[0][0] == -1 || matrix[0][1] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[2][0] == -1 && matrix[2][1] == -1 ){
                if (matrix[0][0] == -1 || matrix[1][0] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[0][5] == -1 && matrix[1][5] == -1 ){
                if (matrix[0][6] == -1 || matrix[0][7] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[2][6] == -1 && matrix[2][7] == -1 ){
                if (matrix[1][7] == -1 || matrix[2][7] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[7][2] == -1 && matrix[8][2] == -1 ){
                if (matrix[8][0] == -1 || matrix[8][1] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[6][0] == -1 && matrix[6][1] == -1 ){
                if (matrix[7][0] == -1 || matrix[8][0] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[7][5] == -1 && matrix[8][5] == -1 ){
                if (matrix[8][7] == -1 || matrix[8][6] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
            if (matrix[6][6] == -1 && matrix[6][7] == -1 ){
                if (matrix[7][7] == -1 || matrix[8][7] == -1 ){
                    restart(a:a, b:b)
                    return
                }
            }
        }
        matrix_copy = matrix
        flags = Array(repeating: Array(repeating: 0, count: num_cols), count: num_rows)
        borders = Array(repeating: Array(repeating: 0, count: num_cols), count: num_rows)
        
        func visualize(){ // should visualize the board
            print("BoardState:\t\t\t\t\tFlags:\t\t\t\t\t\tMap Expansion:")
            for ((matrixRow, flagRow), borderRow) in zip(zip(matrix_copy, flags), borders) {
                let matrixLine = matrixRow.map { String(format: "%2d", $0) }.joined(separator: " ")
                let flagLine = flagRow.map { $0 == 1 ? " F" : " ." }.joined(separator: " ")
                let borderLine = borderRow.map { (value: Int) -> String in
                    switch value {
                    case 1: return " X"
                    case 2: return " /"
                    case -1: return " F"
                    default: return " ."
                    } }.joined(separator: " ")
                        print("\(matrixLine)\t\t\(flagLine)\t\t\(borderLine)")
            }
        
        }
        func neighbors(x: Int, y: Int) -> [(Int, Int)] {
            var a_list: [(Int, Int)] = []
            for x_n in (x - 1)...(x + 1) {
                for y_n in (y - 1)...(y + 1) {
                    if x_n >= 0 && x_n < num_rows && y_n >= 0 && y_n < num_cols {
                        if (matrix_copy[x_n][y_n] != 9){
                            a_list.append((x_n, y_n))
                        }
                    }
                }
            }
            return a_list
        }
        func expand(x: Int, y: Int){//x is row, y is col
            matrix_copy[x][y] = 9
            for (x_prime, y_prime) in neighbors(x:x, y:y){
                borders[x_prime][y_prime] = 1
                if(matrix_copy[x_prime][y_prime] == 0){
                    matrix_copy[x_prime][y_prime] = 9
                    expand(x:x_prime, y:y_prime)
                }
            }
        }
        func naked_single_flagger(used_as_helper: Bool) -> Bool{
            var counter = 0
            var flag_prog: Bool = false;
            for row_index in 0..<num_rows {
                for col_index in 0..<num_cols {
                    if matrix_copy[row_index][col_index] == 9{
                        borders[row_index][col_index] = 2
                    } else {
                        counter = 0;
                        if borders[row_index][col_index] == 1 {
                            for (x_prime, y_prime) in neighbors(x:row_index, y:col_index){
                                if (borders[x_prime][y_prime] < 1){
                                counter += 1
                                }
                            }
                            if counter == matrix_copy[row_index][col_index]{
                                //naked single found
                                borders[row_index][col_index] = 2
                                for (x_prime, y_prime) in neighbors(x:row_index, y:col_index){
                                    if (borders[x_prime][y_prime] == 0){
                                    flags[x_prime][y_prime] = 1
                                    borders[x_prime][y_prime] = -1
                                        if (used_as_helper){
                                            buttons[x_prime][y_prime].text = "💡";
                                            flag_prog = true
                                        }
                                    }
                                }
                                if (flag_prog) {
                                    return true;
                                }
                            
                            }
                        }
                    }
                }
            }
            if !used_as_helper {
                visualize()
            }
            for row_index in 0..<num_rows { //now we re-check perimeter with new flags
                for col_index in 0..<num_cols {
                    if borders[row_index][col_index] == 1{ //on perimeter
                        counter = 0;
                        for (x_prime, y_prime) in neighbors(x:row_index, y:col_index){
                            if flags[x_prime][y_prime] == 1 {
                                counter += 1
                            }
                        }
                        if matrix_copy[row_index][col_index] == counter {
                            //new expansion possible
                            borders[row_index][col_index] = 2
                            if (used_as_helper){
                                for (x_prime, y_prime) in neighbors(x:row_index, y:col_index){
                                    if (flags[x_prime][y_prime] == 0 && borders[x_prime][y_prime] == 0){
                                        buttons[x_prime][y_prime].text = "💡";
                                    }
                                }
                                return true
                            }
                            for (x_prime, y_prime) in neighbors(x:row_index, y:col_index){
                                if (flags[x_prime][y_prime] == 0 && borders[x_prime][y_prime] == 0){
                                    //expand(x:x_prime, y:y_prime)
                                    print("expand on (\(x_prime), \(y_prime))")
                                    borders[x_prime][y_prime] = 1
                                }
                            }
                        }
                        
                    }
                }
            }
            return false;
        }
        func is_done(a: Int) -> Bool {
            for row in borders{
                for item in row{
                    if item == 0{
                        return false;
                    }
                }
            }
            print("BOARD COMPLETE.")
            if (a == 0){
                print("Expected difficulty: Easy.")
            }
            else {
                if ( a < 3 ) {
                    print("Expected difficulty: Medium.")
                } else {
                    print("Expected difficulty: Hard.")
                }
            }
            return true;
        }
        func give_cell_id(x: Int, y:Int) -> Int {//x is row, y is col
            return x*num_cols + y
        }
        func give_coords_from_id(id: Int) -> [Int] {
            let x = id / num_cols
            let y = id % num_cols
            return [x, y]
        }
        
        func find_grouping_constraints(used_as_helper: Bool) -> Bool{
            var my_subgroups: [[Set<Int>]] = []
            var s1_id_set: Set<Int> = []
            var s2_id_set: Set<Int> = []
            var s1_num: Set<Int> = []
            var s2_num: Set<Int> = []
            
            var flagcount: Int = 0
            for row_index in 0..<num_rows {
                for col_index in 0..<num_cols {
                    if borders[row_index][col_index] == 1{ // if on perimeter
                        flagcount = 0
                        var a_set: Set<Int> = []
                        for (x_prime, y_prime) in neighbors(x:row_index, y:col_index){
                            if borders[x_prime][y_prime] == 0{ // for all unflipped adjacencies
                                a_set.insert(give_cell_id(x:x_prime, y:y_prime))
                            }
                            if flags[x_prime][y_prime] == 1 {
                                flagcount += 1
                            }
                        }
                        let count = matrix_copy[row_index][col_index] - flagcount
                        my_subgroups.append([Set([count]), a_set])
                    }
                }
            }
            print(my_subgroups)
            my_subgroups = my_subgroups.filter { subgroup in
                // Check if the first set has exactly one element
                return subgroup[0].count == 1 && subgroup.count == 2 //dump malformities just in case
            }
            for (i, s1) in my_subgroups.enumerated() {
                s1_id_set = s1[1]
                s1_num = s1[0]
                for (j, s2) in my_subgroups.enumerated() {
                    if (j == i){
                        continue
                    }
                    s2_id_set = s2[1]
                    s2_num = s2[0]
                    if s2_id_set.isSubset(of: s1_id_set){//s1 is bigger here.
                        if s1_id_set.isSubset(of: s2_id_set){
                            continue; //NOT OF SUBSETS OF EACH OTHER
                        }
                        s1_id_set.subtract(s2_id_set)
                        if let outer = s1_num.first { // bomb count for outside set
                            if let inner = s2_num.first { // bomb count for inside set
                                let total = Array(s1_id_set) // cell ids by which sets differ
                                if (outer - inner == total.count){
                                    if(used_as_helper){
                                        for item in total{ // should be flagged
                                            let item_coords = give_coords_from_id(id: item)
                                            buttons[item_coords[0]][item_coords[1]].text = "💡"
                                            return true;
                                        }
                                    }
                                    //then every element in total count will be a bomb
                                    for item in total{
                                        let item_coords = give_coords_from_id(id: item)
                                        flags[item_coords[0]][item_coords[1]] = 1
                                        
                                        print("\t--> from subgroups, flagging \(item_coords)")
                                    }
                                }
                                if (outer - inner == 0){
                                    if(used_as_helper){
                                        for item in total{ // should be flagged
                                            let item_coords = give_coords_from_id(id: item)
                                            buttons[item_coords[0]][item_coords[1]].text = "💡"
                                            return true;
                                        }
                                    }
                                    for item in total{
                                        let item_coords = give_coords_from_id(id: item)
                                        borders[item_coords[0]][item_coords[1]] = 1
                                        print("\t--> from subgroups, expanding \(item_coords)")
                                    }
                                }
                            }
                        }
                        
                    }
                    
                }
                
            }
            return false;

        }
        
        
        
        func solve(s_r: Int, s_c: Int) -> Bool {
            print("~~")
            /*(s_r, s_c) are the start coordinates
            function returns a bool if the board is solveable
            */
            print("start values: \(s_r), \(s_c)")
            borders[s_r][s_c] = 1
            //matrix_copy[s_r][s_c] = 9
            expand(x:s_r, y:s_c)
            print("Preliminary Board:")
            visualize()
            print(" ")
            var borders_copy_outer = borders
            var borders_copy_inner = borders
            _ = naked_single_flagger(used_as_helper: false)
            visualize()
            //while borders copy remains different from borders, continue expansion.
            var difficulty: Int = 0
            while borders_copy_outer != borders {
                borders_copy_outer = borders
                if is_done(a: difficulty){
                    return true
                }
                print("\nPROGRESS MADE, simple solve executing")
                
                while borders_copy_inner != borders {
                    borders_copy_inner = borders
                    _ = naked_single_flagger(used_as_helper: false)
                    visualize()
                    if is_done(a: difficulty){
                        return true
                    }
                }
                difficulty += 1
                _ = find_grouping_constraints(used_as_helper: false)
                
            }
            

            //preliminary setup done. move on to first solve sequence
            
            
            print("\nPROGRESS HALTED, NOT SOLVEABLE")
            
            
            return false
            
        }
        
        
        let solve_bool = solve(s_r:a, s_c:b)
        print("solve bool: \(solve_bool)")
        if (ng){
            if solve_bool == false {
                restart(a:a, b:b);
            }
        }

        //toggleTimer()
        timeElapsed = 0.0
        timerRunning = true
        
        
    }///////////////////////////////////////////////////////////////////////////////////
    
    
    
    func explore(row: Int, col: Int) {
        if buttons[row][col].flag == true {
            return
        }
        if buttons[row][col].color != Color.gray{
            return
        }
        if buttons[row][col].bool == true {
            buttons[row][col].color = Color.red;
            buttons[row][col].text = "💥";
            gameCease = true
            timerRunning = false
        } else {
            if let c = colorDict[buttons[row][col].int] {
                buttons[row][col].color = c
            } else { buttons[row][col].color = Color.white }
            
            if (buttons[row][col].int == 0){
                buttons[row][col].text = ""
                for adj_r in row-1..<row+2 {
                    for adj_c in col-1..<col+2 {
                        if adj_r >= 0 && adj_c >= 0 {
                            if (adj_r < num_rows && adj_c < num_cols){
                                if(buttons[adj_r][adj_c].color == Color.gray){
                                    explore(row:adj_r, col:adj_c)
                                }
                            }
                        }
                    }
                }
            }else {
                buttons[row][col].text = String(buttons[row][col].int)
            }
        }
        tilesClicked += 1
        
    }
    func flag(row: Int, col: Int) {
        if (buttons[row][col].flag == false) {
            if (buttons[row][col].color == .gray){
                num_flagged += 1;
                buttons[row][col].color = Color.yellow;
                buttons[row][col].text = "🚩";
                buttons[row][col].flag = true;
            }
        }else {
            num_flagged -= 1;
            buttons[row][col].color = Color.gray;
            buttons[row][col].text = "";
            buttons[row][col].flag = false;
        }
    }
    

    

}

struct ButtonState {
    var color: Color // grey for no bomb, etc
    var text: String // what is displayed (text) on this tile
    var int: Int // number of existing adjacent bombs
    var bool: Bool // exists a bomb on this square
    var flag: Bool // exists a flag on this square
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
