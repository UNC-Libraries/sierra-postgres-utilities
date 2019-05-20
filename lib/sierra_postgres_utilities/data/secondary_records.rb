# It seems useful to draw a distinction between "records" which are reflected
# in record_metadata (i.e. bib, item, etc.) and record-like objects not
# present in record_metadata. They're being grouped here as "secondary records"
# or "second-class records." because they seem more record-like than, say,
# itype, but that distinction is possibly nebulous and of questionable
# usefulness.

module Sierra
  module Data
    require_relative 'secondary_records/hold'
    require_relative 'secondary_records/user'
  end
end
