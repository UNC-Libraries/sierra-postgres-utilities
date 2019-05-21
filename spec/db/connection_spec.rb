require 'spec_helper'

module Sierra
  module DB
    RSpec.describe Connection do
      describe '.base_dir' do
        it 'string path to the base sierra-postgres-utilities dir' do
          expect(File.join(Connection.base_dir, 'spec', 'db',
                           'connection_spec.rb')).to eq(__FILE__)
        end
      end
    end
  end
end
