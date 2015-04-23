require File.dirname(__FILE__) + '/spec_helper'

require 'nokogiri'

describe Aquel do
  describe 'TSV parser' do
    let(:tsv_path) {
      File.dirname(__FILE__) + '/test.tsv'
    }

    let(:aquel) {
      Aquel.define 'tsv' do
        document do |attributes|
          open(attributes['path'])
        end

        item do |document|
          document.gets
        end

        split do |item|
          item.chomp.split(/\t/)
        end
      end
    }

    context 'simple query' do
      it 'finds matching line' do
        # TODO: support prepared statement
        items = aquel.execute("select * from tsv where path = '#{tsv_path}'")

        expect(items.size).to eql(2)
        expect(items.first).to eql(%w/foo1 bar1 baz1/)

        items = aquel.execute("select 1,3 from tsv where path = '#{tsv_path}'")

        expect(items.size).to eql(2)
        expect(items.first).to eql(%w/foo1 baz1/)
      end
    end

    context 'filter query' do
      it 'finds matching line' do
        # TODO: support prepared statement
        items = aquel.execute("select * from tsv where path = '#{tsv_path}' and 1 = 'foo2'")

        expect(items.size).to eql(1)
        expect(items.first).to eql(%w/foo2 bar2 baz2/)

        items = aquel.execute("select 1,3 from tsv where path = '#{tsv_path}' and 1 = 'foo1'")

        expect(items.size).to eql(1)
        expect(items.first).to eql(%w/foo1 baz1/)

        items = aquel.execute("select 1,3 from tsv where path = '#{tsv_path}' and 1 != 'foo1'")

        expect(items.size).to eql(1)
        expect(items.first).to eql(%w/foo2 baz2/)
      end
    end
  end

  describe 'HTML parser' do
    let(:html_path) {
      File.dirname(__FILE__) + '/test.html'
    }

    context 'items' do
      let(:aquel) {
        Aquel.define 'html' do
          document do |attributes|
            Nokogiri::HTML(open(attributes['path']))
          end

          items do |document|
            document.css('div.foo')
          end

          split do |item|
            item.text
          end
        end
      }

      context 'simple query' do
        it 'finds matching line' do
          items = aquel.execute("select * from html where path = '#{html_path}'")

          expect(items.size).to eql(2)
          expect(items.first).to eql(['a'])
        end
      end
    end

    context 'find_by' do
      let(:aquel) {
        Aquel.define 'html' do
          document do |attributes|
            Nokogiri::HTML(open(attributes['path']))
          end

          find_by('css') do |css, document|
            document.css(css)
          end

          split do |item|
            item.text
          end
        end
      }

      context 'simple query' do
        it 'finds matching line' do
          items = aquel.execute("select * from html where path = '#{html_path}' and css = 'div.foo'")

          expect(items.size).to eql(2)
          expect(items.first).to eql(['a'])
        end
      end
    end
  end
end
