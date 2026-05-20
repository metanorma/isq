# frozen_string_literal: true

module Isq
  class Designation < TermInstance
    attribute :index_as, :string, collection: true
  end
end
