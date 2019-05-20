require 'spec_helper'

module Sierra
  RSpec.describe Logging do
    let(:io) { StringIO.new }
    let(:log) { Sierra.log_to(io) }

    describe '#log_to' do
      it 'logs to passed object' do
        log.warn('test')
        expect(io.string).to match('test')
      end

      it 'returns log' do
        expect(log).to be_a(Logger)
      end
    end

    describe '#log_sql' do
      it 'turns on logging of sql queries made' do
        log
        Sierra.log_sql
        Sierra::Data::Bib.first
        expect(io.string).to include('SELECT * FROM')
      end

      context 'when passed false' do
        it 'turns of logging of sql queries' do
          log
          Sierra.log_sql(false)
          Sierra::Data::Bib.first
          expect(io.string).not_to include('SELECT * FROM')
        end
      end
    end
  end
end
