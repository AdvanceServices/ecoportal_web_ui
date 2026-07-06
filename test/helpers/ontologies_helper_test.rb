require 'test_helper'

class OntologiesHelperTest < ActiveSupport::TestCase
  include OntologiesHelper
  include UrlsHelper

  test 'show_ontology_domains splits comma separated values and keeps uri entries' do
    domains = [
      'https://data.ecoportal.lifewatch.eu/categories/Aquatic_Ecology, https://vocabs.lter-europe.net/EnvThes/en/page/20948',
      { '@id' => 'https://data.ecoportal.lifewatch.eu/categories/Aquatic_Ecology', 'name' => 'Aquatic Ecology' }
    ]

    normalized = show_ontology_domains(domains)

    assert_equal 2, normalized.size
    assert_includes normalized.map { |domain| domain[:id] }, 'https://vocabs.lter-europe.net/EnvThes/en/page/20948'

    category_entry = normalized.find { |domain| domain[:id] == 'https://data.ecoportal.lifewatch.eu/categories/Aquatic_Ecology' && domain[:label] == 'Aquatic Ecology' }
    assert category_entry.present?
  end

  test 'ontology_domain_label fetches an external preferred label' do
    stub_request(:get, 'https://vocabs.lter-europe.net/EnvThes/en/page/20948')
      .to_return(
        status: 200,
        body: "<html><head><meta property='skos:prefLabel' content='Marine ecology'><title>20948</title></head></html>",
        headers: { 'Content-Type' => 'text/html' }
      )

    Rails.cache.clear

    assert_equal 'Marine ecology', ontology_domain_label('https://vocabs.lter-europe.net/EnvThes/en/page/20948')
  end

  test 'ontology_subject_domains finds EnvThes uris anywhere in the submission payload' do
    submission = OpenStruct.new(
      to_hash: {
        unrelated: 'value',
        nested: {
          another: [
            'https://vocabs.lter-europe.net/EnvThes/en/page/20728'
          ]
        }
      }
    )

    normalized = ontology_subject_domains(submission)

    assert_equal 1, normalized.size
    assert_equal 'https://vocabs.lter-europe.net/EnvThes/en/page/20728', normalized.first[:id]
  end
end
