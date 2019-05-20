module Sierra
  module Data
    class BibRecordProperty < Sequel::Model(DB.db[:bib_record_property])
      set_primary_key :id

      one_to_one :bib, key: :id, primary_key: :bib_record_id
    end
  end
end
