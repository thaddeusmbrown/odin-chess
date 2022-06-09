require 'colorize'
require 'pry-byebug'

# Main, starts and runs game
class Chess
  def initialize
    @board = Board.new
    @turns = [@white, @black]
    @turn = 0
    # ask_ai() implement this function last, optional
    next_turn
  end

  def next_turn

  end
end

# creates the board, stores piece locations, and displays
# @board is a 2-D array, outer level (i: 0-7) is a-g, inner level (j: 0-7) is 1-8
class Board
  def initialize
    @white_player = Player.new('white')
    @black_player = Player.new('black')
    @board = Array.new(8) { Array.new(8, nil) }
    @black = '  '.on_magenta
    @white = '  '.on_light_magenta
    @odd_row = [@black, @white, @black, @white, @black, @white, @black, @white]
    @even_row = @odd_row.reverse
    display_board
  end

  def display_board
    @board.reverse.each_with_index do |row, index|
      row_type = index.even? ? Array.new(@even_row) : Array.new(@odd_row)
      reverse_index = 7 - index
      @white_player.pieces.each do |piece|
        if piece.location[0] == reverse_index
          if (piece.location[0] + piece.location[1]).odd?
            row_type[piece.location[1]] = piece.icon.white.on_light_magenta + ' '.on_light_magenta
          else
            row_type[piece.location[1]] = piece.icon.white.on_magenta + ' '.on_magenta
          end
        end
      end
      @black_player.pieces.each do |piece|
       # binding.pry if reverse_index == 5
        if piece.location[0] == reverse_index
          if (piece.location[0] + piece.location[1]).odd?
            row_type[piece.location[1]] = piece.icon.black.on_light_magenta + ' '.on_light_magenta
          else
            row_type[piece.location[1]] = piece.icon.black.on_magenta + ' '.on_magenta
          end
        end
      end
      puts reverse_index.to_s + ' ' + row_type.join
    end
    puts '  a b c d e f g h'
  end
end

# one white and one black player, stores and controls pieces
class Player
  attr_reader :pieces

  def initialize(color)
    @side = color
    @pieces = create_pieces
  end

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
end

# base class for shared properties of all pieces
class Piece
  attr_reader :side, :location, :icon

  def initialize(col, side)
    @side = side
    @location = side == 'white' ? [0, col] : [7, col]
  end
end

# pawn-specific class, controls en passant and promotion
class Pawn < Piece
  def initialize(col, side)
    super
    @location = side == 'white' ? [1, col] : [6, col]
    @icon = "\u265f".encode('utf-8')
  end
end

# knight-specific class
class Knight < Piece
  def initialize(col, side)
    super
    @icon = "\u265e".encode('utf-8')
  end
end

# bishop-specific class
class Bishop < Piece
  def initialize(col, side)
    super
    @icon = "\u265d".encode('utf-8')
  end
end

# rook specific class
class Rook < Piece
  def initialize(col, side)
    super
    @icon = "\u265c".encode('utf-8')
  end
end

# queen-specific class
class Queen < Piece
  def initialize(col, side)
    super
    @icon = "\u265b".encode('utf-8')
  end
end

# king-specific class, controls castling and victory
class King < Piece
  def initialize(col, side)
    super
    @icon = "\u265a".encode('utf-8')
  end
end
Board.new
