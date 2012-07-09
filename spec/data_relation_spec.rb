require File.expand_path("../../lib/data_relation", __FILE__)

module DataRelation
  describe Collection do
    class Datum < Struct.new(:id, :name, :score, :freelance); end

    let(:donald) { Datum.new(1, 'Donald', 6.0, 0) }
    let(:angela) { Datum.new(2, 'Angela', 6.8, 0) }
    let(:avdi) { Datum.new(3, 'Avdi', 6.5, 1) }
    let(:gary) { Datum.new(4, 'Gary', 6.7, 1) }
    let(:data) { [donald, angela, avdi, gary] }
    let(:collection) {
      collection = Collection.new(data)
    }

    it "equals the original data" do
      collection.should == data
    end

    it "copies the original data when converting to an array" do
      collection.to_a.should == data
      collection.to_a << 'foo'
      data.length.should == 4
    end

    describe "order" do
      it "by a field asc" do
        collection.order('name ASC').should ==
          [angela, avdi, donald, gary]
      end

      it "by a field desc" do
        collection.order('name desc').should ==
          [gary, donald, avdi, angela]
      end

      it "by the last order" do
        collection.order('name asc').order('name desc').should == 
          [gary, donald, avdi, angela]
      end

      it "by multiple fields" do
        collection.order('freelance desc, score desc').should ==
          [gary, avdi, angela, donald]
      end

      it "raises ArgumentError on invalid direction" do
        lambda { collection.order('name foo') }.should raise_error ArgumentError
      end
    end

    describe "where" do
      it "to a hash with core values" do
        collection.where('freelance' => 0).should ==
          [donald, angela]
      end

      it "to a hash with list values" do
        collection.where('name' => %w(Avdi Gary)).should ==
          [avdi, gary]
      end

      it "to a hash with range values" do
        collection.where('score' => (6.7 .. 6.9)).should ==
          [angela, gary]
      end
    end
  end
end
