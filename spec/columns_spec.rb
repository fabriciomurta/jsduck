require "jsduck/columns"

describe JsDuck::Columns do

  # Small helper to check the sums
  def sum(arr)
    arr.reduce(0) {|sum,x| sum + x }
  end

  # Replace the sum method with the one that simply sums the numbers,
  # so we can use simpler test-data.
  class JsDuck::Columns
    def sum(arr)
      arr.reduce(0) {|sum,x| sum + x }
    end
  end

  describe "#split" do
    before do
      @columns = JsDuck::Columns.new("classes")
    end

    it "split(1 item by 1)" do
      @cols = @columns.split([2], 1)
      expect(@cols.length).to eq(1)
      expect(sum(@cols[0])).to eq(2)
    end

    it "split(3 items by 1)" do
      @cols = @columns.split([1, 2, 3], 1)
      expect(@cols.length).to eq(1)
      expect(sum(@cols[0])).to eq(6)
    end

    it "split(3 items to two equal-height columns)" do
      @cols = @columns.split([1, 2, 3], 2)
      expect(@cols.length).to eq(2)
      expect(sum(@cols[0])).to eq(3)
      expect(sum(@cols[1])).to eq(3)
    end

    it "split(1 item by 3)" do
      @cols = @columns.split([2], 3)
      expect(@cols.length).to eq(3)
      expect(sum(@cols[0])).to eq(2)
      expect(sum(@cols[1])).to eq(0)
      expect(sum(@cols[2])).to eq(0)
    end

    it "split(3 items by 3)" do
      @cols = @columns.split([1, 2, 3], 3)
      expect(@cols.length).to eq(3)
      expect(sum(@cols[0])).to eq(1)
      expect(sum(@cols[1])).to eq(2)
      expect(sum(@cols[2])).to eq(3)
    end

    it "split(6 items by 3)" do
      @cols = @columns.split([5, 8, 4, 2, 1, 3], 3)
      expect(@cols.length).to eq(3)
      sum(@cols[0]).should <= 10
      sum(@cols[1]).should <= 10
      sum(@cols[2]).should <= 10
    end

    it "split(8 items by 3)" do
      @cols = @columns.split([1, 3, 5, 2, 1, 4, 2, 3], 3)
      expect(@cols.length).to eq(3)
      sum(@cols[0]).should <= 9
      sum(@cols[1]).should <= 9
      sum(@cols[2]).should <= 9
    end
  end

end
