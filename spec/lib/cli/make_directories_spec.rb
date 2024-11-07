# frozen_string_literal: true
require "spec_helper"
module Parkive
  RSpec.describe "Parkive::CLI#make_directories" do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }
    let(:this_year) { Time.now.year.to_s }

    context "when no destination is provided" do
      it "fails with a usage error" do
        expect do
          CLI.new.invoke(:make_directories)
        end.to raise_error(Thor::InvocationError)
      end
    end

    context "when the destination does not exist" do
      it "does not create a directory" do
        expect do
          CLI.new.invoke(:make_directories, ["#{temp_dir}/foo"])
        end.to raise_error(StandardError)
        expect(File.exist?("#{temp_dir}/foo/#{this_year}")).to eq(false)
      end

      it "fails with a useful error" do
        expect do
          CLI.new.invoke(:make_directories, ["#{temp_dir}/foo"])
        end.to raise_error(NoDestinationDirectoryError)
      end
    end

    context "when the destination root exists" do
      context "when the year is not specified" do
        it "creates the expected directories" do
          CLI.new.invoke(:make_directories, ["#{temp_dir}"])

          root = File.join(temp_dir, this_year)
          expect(Dir.exist?(root)).to eq(true)

          dirs = Dir.glob(File.join(root, "*")).sort

          expect(dirs).to eq([File.join(root, "01.Jan"),
                              File.join(root, "02.Feb"),
                              File.join(root, "03.Mar"),
                              File.join(root, "04.Apr"),
                              File.join(root, "05.May"),
                              File.join(root, "06.Jun"),
                              File.join(root, "07.Jul"),
                              File.join(root, "08.Aug"),
                              File.join(root, "09.Sep"),
                              File.join(root, "10.Oct"),
                              File.join(root, "11.Nov"),
                              File.join(root, "12.Dec"),
                              File.join(root, "#{this_year}.Media"),
                              File.join(root, "#{this_year}.Tax")])
        end

        context "when the year is specified" do
          it "creates the expected directories" do
            CLI.new.invoke(:make_directories, ["#{temp_dir}"], { year: "2002" })

            root = File.join(temp_dir, "2002")
            expect(Dir.exist?(root)).to eq(true)

            dirs = Dir.glob(File.join(root, "*")).sort

            expect(dirs).to eq([File.join(root, "01.Jan"),
                                File.join(root, "02.Feb"),
                                File.join(root, "03.Mar"),
                                File.join(root, "04.Apr"),
                                File.join(root, "05.May"),
                                File.join(root, "06.Jun"),
                                File.join(root, "07.Jul"),
                                File.join(root, "08.Aug"),
                                File.join(root, "09.Sep"),
                                File.join(root, "10.Oct"),
                                File.join(root, "11.Nov"),
                                File.join(root, "12.Dec"),
                                File.join(root, "2002.Media"),
                                File.join(root, "2002.Tax")])
          end
        end
      end
    end
  end
end
