require 'marc'
module Sierra
  module Data
    module Helpers
      module SierraMARC
        # Retrieves cached marc or compiles and caches marc
        #
        # @return [MARC::Record]
        def marc
          @marc ||= compile_marc
        end

        # Compiles and caches marc, even if cached marc exists.
        #
        # @return [MARC::Record]
        def compile_marc
          @marc = Sierra::Data::Helpers::SierraMARC.compile_marc(self)
        end

        # Compiles and caches marc, atypically.
        #
        # This uses prepared statements which may be quicker than #marc /
        # #compile_marc's use of associations for leader/control/varfields.
        # However this method does not cache the leader/control/varfield values,
        # it retrieves, so is likely slower if you also will need to retrieve
        # those associations/fields for other reasons.
        def quick_marc
          @marc = Sierra::Data::Helpers::SierraMARC.compile_marc(
            self,
            ldr: @leader_field || Sierra::Data::LeaderField.
                                    by_record_id(record_id: id),
            cfs: @control_fields || Sierra::Data::ControlField.
                                      by_record_id(record_id: id),
            vfs: @varfields || Sierra::Data::Varfield.
                                 by_record_id(record_id: id)
          )
        end

        # Sets marc
        #
        # @param [MARC::Record] marc
        # @return [MARC::Record]
        def marc=(marc)
          @marc = marc
        end

        # Compiles marc for a record.
        #
        # Uses the record's leader/controlfield/varfield associations, unless
        # passed leader/controlfield/varfield values.
        #
        # @param [Sierra::Data::Bib, Sierra::Data::Authority, ...] rec
        # @param [Sierra::Data::LeaderField] ldr
        # @param [Enumerable<Sierra::Data::ControlField>] cfs
        # @param [Enumerable<Sierra::Data::Varfield>] vfs
        # @return [MARC::Record]
        def self.compile_marc(rec, ldr: nil, cfs: nil, vfs: nil)
          ldr ||= rec.leader_field
          cfs ||= rec.control_fields
          vfs ||= rec.varfields

          m = MARC::Record.new
          m.leader = ldr.to_s if ldr

          vfs.select(&:control_field?).map(&:to_marc).each do |cf|
            m << cf if cf
          end
          cfs.each { |c| m << c.to_marc }
          vfs.reject(&:control_field?).map(&:to_marc).each do |df|
            m << df if df
          end

          m
        end
      end
    end
  end
end
