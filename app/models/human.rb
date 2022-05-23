require 'matrix'

class Human < Piece
  belongs_to :game

  def print_label(view = :humans)
    'H'
  end

  def place_bomb(v)
    ActiveBomb.create({ x_position: x_position + v[0],
                        y_position: y_position + v[1],
                        game_id: game.id })
    game.humans_bombs -= 1
  end

  def valid_bomb_placement?(v)
    game.humans_bombs > 0 &&
    valid_move?(v, position, last_move) &&
    !card_on?(self.position + Vector.elements(v))
  end

  # third parameter is included because worm version of valid_move needs it
  def valid_move?(v, starting_square, _)
    valid_move_geometry?(v, starting_square) &&
    !human_on?(self.position + Vector.elements(v)) &&
    !active_bomb_on?(self.position + Vector.elements(v)) &&
    !moving_from_rock_to_rock?(v)
  end

  def valid_move_geometry?(v, starting_square)
    on_board?(starting_square) &&
    on_board?(Vector[*starting_square] + Vector[*v]) &&
    kings_move?(v) &&
    number_of_king_moves_away(v) == 1
  end

  def kings_move?(v)
    v[0] == 0 && [-1, 1].include?(v[1]) ||
    v[1] == 0 && [-1, 1].include?(v[0]) ||
    [-1, 1].include?(v[0]) && v[0].abs == v[1].abs
  end

  def human_on?(square)
    game.humans.each do |h|
      if square[0] == h.x_position && square[1] == h.y_position
        return true
      end
    end
    false
  end

  def moving_from_rock_to_rock?(v)
    rocks = game.cards.where(type: 'Rock', face_up: true)
    game.item_on_square(rocks, position) &&
    game.item_on_square(rocks, position + Vector.elements(v))
  end

  def card_on?(square)
    game.cards.each do |c|
      if square[0] == c.x_position && square[1] == c.y_position
        return true
      end
    end
    false
  end

  def die!
    self.alive = false
    self.x_position = nil
    self.y_position = nil
    self.save
    game.worm_message = 'You just ate a human'
    game.humans_message = 'One of your humans was just eaten'
    game.save
  end

  # for passing into valid_move since human's last move is unimportant
  def last_move
    nil
  end
end
