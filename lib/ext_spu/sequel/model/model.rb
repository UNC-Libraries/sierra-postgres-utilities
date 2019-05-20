# Extends Sequel.
module Sequel
  # Extends Sequel::Model.
  class Model
    # Creates a prepared statement to retrieve instance(s) of the model
    # and a class method on the model to use that prepared statement.
    #
    # @param [Symbol] field the column on the target class/table to match
    #   against
    # @param [Symbol] select_type the form the results should take.
    #   Perhaps here, most often :select or :first
    #
    #   @see http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset/PreparedStatementMethods.html#method-i-prepared_sql
    # @param [Array<Symbol>] sorting optionally specify fields to order by
    # @return void
    # @example Create prepared statement / method to retrieve varfields for a
    # record_id.
    #   Sierra::Data::Varfield.prepare_retrieval_by(
    #     :record_id,
    #     :select,
    #     sorting: %i[marc_tag varfield_type_code occ_num id]
    #   )
    def self.prepare_retrieval_by(field, select_type, sorting: nil)
      class_name = name.split('::').last.downcase
      statement_name = "#{class_name}_by_#{field}".to_sym

      if sorting
        where(field => :"$#{field}").
          order(sorting).
          prepare(select_type, statement_name)
      else
        where(field => :"$#{field}").
          prepare(select_type, statement_name)
      end

      define_singleton_method :"by_#{field}" do |value|
        Sierra::DB.db.call(statement_name, value)
      end
    end
  end
end
