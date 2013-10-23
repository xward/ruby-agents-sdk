module ProtocolGenerator

  class ProtocolValidator

    # todo(faucon_b) additionnal validation
    def validate(protocol)
      out = {}
      verif = validate_id_uniqueness(protocol)
      out["ID uniqueness"] = verif if verif.size > 0
      out
    end

    # todo(faucon_b) better error messages
    def validate_id_uniqueness(protocol)
      out = []
      duplicates = protocol.sequences.group_by{|seq| seq.id}.select{|k, count| count.size > 1}
      if duplicates.size > 0
        out << "Found duplicate sequences id"
      end
      protocol.sequences.each do |seq|
      duplicates = seq.shots.group_by{|shot| shot.id}.select{|k, count| count.size > 1}
        if duplicates.size > 0
          out << "Found duplicate shots id in sequence #{seq.name}"
        end
      end
      duplicates = protocol.messages.group_by{|msg| msg.id}.select{|k, count| count.size > 1}
      if duplicates.size > 0
          out << "Found duplicate messages id"
      end
      out
    end

  end

end