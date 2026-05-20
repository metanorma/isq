# frozen_string_literal: true

module Isq
  class TermInstance < SduSmart::Term
    attribute :text, :string
    attribute :lang, :string, default: "en"

    def text=(value)
      value_set_for(:text)
      @text = value
    end

    rdf do
      namespace SduSmart::Rdf::Namespaces::SkosXlNamespace,
                SduSmart::Rdf::Namespaces::SmartNamespace

      subject { |m| "https://w3id.org/standards/isoiec80000/ontologies/core/#{m.id}" }

      type ["skosxl:Label", "smart:Term"]

      predicate :literalForm,
                namespace: SduSmart::Rdf::Namespaces::SkosXlNamespace,
                to: :text,
                lang_tagged: true

      predicate :hasTermFormType,
                namespace: SduSmart::Rdf::Namespaces::SmartNamespace,
                to: :term_form_type,
                uri_reference: true
    end
  end
end
