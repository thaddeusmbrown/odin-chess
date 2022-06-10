require 'colorize'
require 'pry-byebug'

# Main, starts and runs game
class Chess
  def initialize
    @board = Board.new
    @turns = ['White', 'Black']
    @turn = 1
    @rank = '12345678'
    @file = 'abcdefgh'
    puts 'Welcome to Chess!'
    # ask_ai() implement this function last, optional
    next_turn
  end

  protected

  def next_turn
    @turn = (@turn * -1) + 1
    player_input
  end

  def player_input
    puts "\n#{@turns[@turn]}, please enter a move.  For help, type 'help'."
    answer = gets.chop
    if answer == 'help'
      help
    else
      check_valid_input(answer)
    end
  end

  def help
    puts "\nTo move a piece, enter its starting location and ending location.\n
For example, 'b1 c2' would move a piece from 'b1' to 'c2'.\n
Castling:  If your king and rooks have not moved and there is space between them, \
you can castle by moving your king two spaces to the left or right.  The rook will \
move one space toward the center from where your king lands.\n
Promotion:  Move a pawn to your opponent's side of the board to promote it to any piece, \
except a king.\n\n
En passant:  If an opponent's pawn moves forward two spaces and lands adjacent to your pawn, \
you can move your pawn diagonally behind it to capture.  This must be done immediately after.\n"
    player_input
  end

  def check_valid_input(answer)
    begin
      raise StandardError if answer.length != 5
      file_start, rank_start, file_end, rank_end = answer[0], answer[1], answer[3], answer[4]
    rescue StandardError
      invalid_input
    end
    if @file.include?(file_start) && @file.include?(file_end) && @rank.include?(rank_start) && @rank.include?(rank_end)
      check_valid_move(file_start, rank_start.to_i, file_end, rank_end.to_i)
    else
      invalid_input
    end
  end

  def check_valid_move(file_start, rank_start, file_end, rank_end)
    file_start, rank_start, file_end, rank_end = file_start.ord - 97, rank_start - 1, file_end.ord - 97, rank_end - 1
    if @turn.zero?
      @board.white_player.pieces.each do |piece|
        set_piece(piece, @board.white_player, @board.black_player) if piece.location == [rank_start, file_start]
      end
    else
      @board.black_player.pieces.each do |piece|
        set_piece(piece, @board.black_player, @board.white_player) if piece.location == [rank_start, file_start]
      end
    end
    no_owned_piece
  end

  def set_piece(piece, friendly_player, enemy_player)
    if piece.is_a?(Pawn)
      valid_moves, en_passant_bit = piece.find_valid_moves(friendly_player, enemy_player)
    else
      valid_moves = piece.find_valid_moves(friendly_player, enemy_player)
    end
  end

  def invalid_input
    puts "Invalid input, try again."
    player_input
  end

  def no_owned_piece
    puts "No owned piece at starting location, try again."
    player_input
  end
end

# creates the board, stores piece locations, and displays
# @board is a 2-D array, outer level (i: 0-7) is a-g, inner level (j: 0-7) is 1-8
class Board
  attr_reader :white_player, :black_player

  def initialize
    @white_player = Player.new('white')
    @black_player = Player.new('black')
    @board = Array.new(8) { Array.new(8, nil) }
    build_board
    @black = '  '.on_magenta
    @white = '  '.on_light_magenta
    @odd_row = [@black, @white, @black, @white, @black, @white, @black, @white]
    @even_row = @odd_row.reverse
    display_board
  end

  protected

  def display_board
    @board.reverse.each_with_index do |row, index|
      row_type = index.even? ? Array.new(@even_row) : Array.new(@odd_row)
      reverse_index = 7 - index
      @board[index].each_with_index do |piece, col|
        unless piece.nil?
          row_type[col] = piece.location.sum.even? ? piece.icon.on_magenta + ' '.on_magenta : piece.icon.on_light_magenta + ' '.on_light_magenta 
        end
      end
      puts (reverse_index + 1).to_s + ' ' + row_type.join
    end
    puts '  a b c d e f g h'
  end

  def build_board
    @board.each_with_index do |row, index|
      reverse_index = 7 - index
      @white_player.pieces.each do |piece|
        row[piece.location[1]] = piece if piece.location[0] == reverse_index
      end
      @black_player.pieces.each do |piece|
        row[piece.location[1]] = piece if piece.location[0] == reverse_index
      end
    end
  end
end

# one white and one black player, stores and controls pieces
class Player
  attr_reader :pieces, :side, :locations

  def initialize(color)
    @side = color
    @pieces = create_pieces
    @locations = []
    refresh_locations
  end

  protected

  def create_pieces
    pieces = []
    (0..7).each do |col|
      pieces.push(Pawn.new(col, @side))
      pieces.push(find_type(col, @side))
    end
    pieces
  end

  def find_type(col, side)
    case col
    when 0, 7
      Rook.new(col, side)
    when 1, 6
      Knight.new(col, side)
    when 2, 5
      Bishop.new(col, side)
    when 3
      Queen.new(col, side)
    when 4
      King.new(col, side)
    end
  end

  def refresh_locations
    @locations = []
    @pieces.each do |piece|
      @locations.push piece.location
    end
  end
end

# base class for shared properties of all pieces
class Piece
  attr_reader :side, :location, :icon, :valid_moves

  def initialize(col, side)
    @side = side
    @location = side == 'white' ? [0, col] : [7, col]
    @valid_moves = []
  end
end

# pawn-specific class, controls en passant and promotion
class Pawn < Piece
  def initialize(col, side)
    super
    @location = side == 'white' ? [1, col] : [6, col]
    @icon = side == 'white' ? "\u265f".encode('utf-8').white : "\u265f".encode('utf-8').black
    @potential_moves = [[2, 0], [1, 0], [1, -1], [1, 1]]
    @move_bit = false
    @en_passant_bit = false
  end

  def find_valid_moves(friendly_player, enemy_player)
    @valid_moves = []
    check_moves = add_check_moves
    on_board_moves = remove_out_board_moves(check_moves)
    open_moves = on_board_moves - friendly_player.locations
    p open_moves
    all_moves = keep_attack_moves(open_moves, enemy_player.locations)
    return add_en_passant(all_moves, enemy_player.pieces)
  end

  def add_check_moves
    check_moves = Array.new(4, @location)
    @potential_moves.each_with_index do |move, index|
      check_moves[index] = [check_moves[index], move].transpose.map(&:sum)
    end
    check_moves.shift if @move_bit
    check_moves
  end

  def remove_out_board_moves(check_moves)
    on_board_moves = []
    check_moves.each do |move|
      on_board_moves.push(move) if move[0].between?(0, 7) && move[1].between?(0, 7)
    end
    on_board_moves
  end

  def keep_attack_moves(open_moves, enemy_locations)
    all_moves = []
    open_moves.each do |move|
      all_moves.push(move) if enemy_locations.include?(move)
    end
    all_moves
  end

  def add_en_passant(all_moves, enemy_pieces)
    final_moves = all_moves
    return final_moves, false if (@side == 'white' && @location[0] != 4) || (@side == 'black' && @location[0] != 3)

    enemy_pieces.each do |piece|
      next unless piece.is_a?(Pawn) && ((@location[1] - piece.location[1])**2) == 1 && piece.en_passant_bit

      final_moves.push(piece.location)
      return final_moves, true
    end
  end
end

# knight-specific class
class Knight < Piece
  def initialize(col, side)
    super
    @icon = side == 'white' ? "\u265e".encode('utf-8').white : "\u265e".encode('utf-8').black
  end
end

# bishop-specific class
class Bishop < Piece
  def initialize(col, side)
    super
    @icon = side == 'white' ? "\u265d".encode('utf-8').white : "\u265d".encode('utf-8').black
  end
end

# rook specific class
class Rook < Piece
  def initialize(col, side)
    super
    @icon = side == 'white' ? "\u265c".encode('utf-8').white : "\u265c".encode('utf-8').black
  end
end

# queen-specific class
class Queen < Piece
  def initialize(col, side)
    super
    @icon = side == 'white' ? "\u265b".encode('utf-8').white : "\u265b".encode('utf-8').black
  end
end

# king-specific class, controls castling and victory
class King < Piece
  def initialize(col, side)
    super
    @icon = side == 'white' ? "\u265a".encode('utf-8').white : "\u265a".encode('utf-8').black
  end
end
Chess.new
