# frozen_string_literal: true

module Isq
  module YamlAdapters
    def definition_from_yaml(model, value)
      return unless value.is_a?(Hash)

      lang = value.keys.first.to_s
      text = value.values.first
      model.definition = Isq::LangString.new(text.to_s, language: lang)
    end

    def definition_to_yaml(model, doc)
      return unless model.definition

      lang = model.definition.language || "en"
      doc["def"] = { lang => model.definition.to_s }
    end

    def note_from_yaml(model, value)
      return unless value.is_a?(Hash)

      lang = value.keys.first.to_s
      text = value.values.first
      model.note = Isq::LangString.new(text.to_s, language: lang)
    end

    def note_to_yaml(model, doc)
      return unless model.note

      lang = model.note.language || "en"
      doc["remarks"] = { lang => model.note.to_s }
    end

    def designations_from_yaml(model, value)
      unless value.is_a?(Array)
        model.designations = []
        return []
      end

      designations = value.each_with_index.map do |entry, i|
        lang_data = entry["designation"]
        next unless lang_data.is_a?(Hash)

        lang = lang_data.keys.first.to_s
        text_data = lang_data[lang] || lang_data[lang.to_sym]
        next unless text_data.is_a?(Hash)

        d = Isq::Designation.new(
          id: "term-#{model.id}-#{i}",
          lang: lang,
          term_form_type: "smart:fullForm",
          index_as: Array(text_data["index_as"]),
        )
        d.text = Isq::LangString.new(text_data["text"].to_s, language: lang)
        d
      end.compact

      model.designations = designations
      model.pref_label = designations.first&.text
      designations
    end

    def designations_to_yaml(model, doc)
      doc["designations"] = model.designations.map do |d|
        { "designation" => { d.lang => { "text" => d.text.to_s, "index_as" => Array(d.index_as) } } }
      end
    end

    def symbols_from_yaml(model, value)
      unless value.is_a?(Array)
        model.symbols = []
        model.notation = []
        return []
      end

      symbols = value.each_with_index.map do |sym, i|
        s = Isq::SymbolTerm.new(
          id: "sym-#{model.id}-#{i}",
          lang: "en",
          term_form_type: "smart:symbol",
        )
        s.text = Isq::LangString.new(sym.to_s, language: "en")
        s
      end

      model.symbols = symbols
      model.notation = symbols.map { |s| s.text.to_s }
      symbols
    end

    def symbols_to_yaml(model, doc)
      doc["symbols"] = model.symbols.map { |s| s.text.to_s }
    end
  end
end
