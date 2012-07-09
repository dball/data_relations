require "data_relation/version"

module DataRelation
  class Collection
    def initialize(data)
      @data = data
    end

    def order(order)
      OrdersCollections.new(self, order).call
    end

    def where(where)
      SearchesCollections.new(self, where).call
    end

    def ==(other)
      @data.==(other)
    end

    def to_a
      @data.dup
    end
  end

  private

  class OrdersCollections
    def initialize(collection, order)
      @collection = collection
      @clauses = order.split(',').map { |value| OrderClause.new(value) }
    end

    def call
      data = @collection.to_a.sort { |o1, o2| compare(o1, o2) }
      @collection.class.new(data)
    end

    def compare(o1, o2)
      @clauses.each do |clause|
        compared = clause.compare(o1, o2) 
        return compared unless compared == 0
      end
      0
    end

    private

    class OrderClause
      def initialize(value)
        @field, direction = value.split
        case direction.downcase
        when 'asc' then @asc = true
        when 'desc' then @asc = false
        else
          raise ArgumentError, "Invalid direction in order clause: #{value}"
        end
      end

      def asc?
        @asc
      end

      def desc?
        !@asc
      end

      def compare(object1, object2)
        value1 = object1.send(@field)
        value2 = object2.send(@field)
        if desc?
          value1, value2 = value2, value1
        end
        value1 <=> value2
      end
    end
  end

  class SearchesCollections
    def initialize(collection, where)
      @collection = collection
      @where = where
    end

    def call
      data = @collection.to_a.select { |object|
        @where.to_a.all? { |key, value|
          actual = object.send(key)
          clause_for(value).matches?(actual)
        }
      }
      @collection.class.new(data)
    end

    private

    def clause_for(value)
      SearchValueClauseFactory.create_for(value)
    end

    class SearchValueClauseFactory
      def self.create_for(value)
        class_for(value).new(value)
      end

      private

      def self.class_for(value)
        case value
        when Array then ListValuedSearchClause
        when Range then ListValuedSearchClause
        else SingleValuedSearchClause
        end
      end
    end

    class SingleValuedSearchClause
      def initialize(value)
        @value = value
      end

      def matches?(value)
        @value == value
      end
    end

    class ListValuedSearchClause
      def initialize(value)
        @value = value
      end

      def matches?(value)
        @value.include?(value)
      end
    end
  end
end
