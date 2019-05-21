require 'spec_helper'

module Sequel
  RSpec.describe Model do
    describe '.prepare_retrieval_by' do
      let(:user) { Sierra::Data::User.first }
      Sierra::Data::User.prepare_retrieval_by(:name, :first)
      Sierra::Data::User.
        prepare_retrieval_by(:account_unit, :select,
                             sorting: %i[last_password_change_gmt name])

      it 'creates a prepared statement' do
        expect(Sierra::DB.db.prepared_statements.keys).to include(:user_by_name)
      end

      it 'defines a "by_{field} method' do
        expect(Sierra::Data::User.by_name(name: user.name)).to eq(user)
      end

      context 'with a select_method of :first' do
        it 'returns the first matching object' do
          expect(Sierra::Data::User.by_name(name: user.name)).to eq(user)
        end
      end

      context 'with a select_method of :select' do
        it 'returns an array of matching objects' do
          expect(Sierra::Data::User.
                 by_account_unit(account_unit: user.account_unit)).
            to include(user)
        end
      end

      it 'sorts results when provided sort order (at statement creation)' do
        users = Sierra::Data::User.
                by_account_unit(account_unit: user.account_unit)
        sorted = users.sort_by do |u|
          [u.last_password_change_gmt || Time.now, u.name]
        end

        expect(users).to eq(sorted)
      end
    end
  end
end
