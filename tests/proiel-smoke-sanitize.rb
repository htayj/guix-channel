#!/usr/bin/env ruby
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Tay
#
# Run from the pinned PROIEL source tree after the origin has removed spec XML.
# All generated text, annotations, token IDs and dictionary records below are
# independently authored synthetic test data, licensed under MIT.  No corpus
# token/edge dataset is retained.  Annotation tag names are functional format
# vocabulary; their fresh summaries are not imported from corpus headers.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'cgi'
require 'fileutils'

abort 'Run in the pinned PROIEL source root' unless File.file?('spec/spec_helper.rb')
abort 'Origin must remove all spec XML first' unless Dir.glob('spec/**/*.xml').empty?

LICENSE_COMMENT = '<!-- SPDX-License-Identifier: MIT; Copyright (c) 2026 Tay. Independent synthetic fixture. -->'
def element(name, attrs = {}, body = nil)
  attributes = attrs.reject { |_, value| value.nil? }.map do |key, value|
    %( #{key}="#{CGI.escapeHTML(value.to_s)}")
  end.join
  body.nil? ? "<#{name}#{attributes}/>" : "<#{name}#{attributes}>#{body}</#{name}>"
end

def document(version, body)
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{LICENSE_COMMENT}\n" +
    element('proiel', { 'schema-version' => version, 'export-time' => '2026-10-02T00:00:00Z' }, body) + "\n"
end

def save_fixture(name, contents)
  path = File.join('spec', name)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, contents)
end

# Complete functional vocabulary used by AnnotationSchema tests.  A relation
# can be primary-only, secondary-only, or both; the tests retain all branches.
relations = %w[adnom adv ag apos arg atr aux comp expl narg nonsub obj obl parpred part per pid pred rel sub voc xadv xobj xsub]
parts = %w[A- C- Df Dq Du F- G- I- Ma Mo N- Nb Ne Pc Pd Pi Pk Pp Pr Ps Pt Px Py R- S- V- X-]
statuses = %w[acc_gen acc_inf acc_sit info_unannotatable kind new no_info_status non_spec non_spec_inf non_spec_old old old_inact quant]
annotation = element('annotation', {},
  element('relations', {}, relations.map { |tag|
    element('value', {tag: tag, summary: "Test relation #{tag}", primary: !%w[pid xsub].include?(tag), secondary: true})
  }.join) +
  element('parts-of-speech', {}, parts.map { |tag| element('value', {tag: tag, summary: "Test POS #{tag}"}) }.join) +
  element('morphology', {}, element('field', {tag: 'case'}, element('value', {tag: 'a', summary: 'Test accusative'}))) +
  element('information-statuses', {}, statuses.map { |tag| element('value', {tag: tag, summary: "Test status #{tag}"}) }.join))

# An intentionally nonlinguistic dependency tree: a branching root, a deep
# ancestry chain, and all three null sorts.  It is NOT a renamed corpus graph.
forms = %w[Orin builds bright models beside quiet blue lamps]
heads = [102, nil, 104, 102, 104, 105, 106, 107, 106, 109, 110, 102]
main_tokens = (0...12).map do |index|
  attrs = {id: 101 + index, 'head-id' => heads[index], relation: index == 1 ? 'pred' : 'atr'}
  if index < forms.length
    attrs.merge!({form: forms[index], lemma: forms[index], 'part-of-speech' => index == 1 ? 'V-' : 'Ne',
                  morphology: index == 1 ? '3spia----i' : '-s---na--i', 'citation-part' => '1.1.1',
                  'presentation-after' => index == 7 ? '. ' : ' '})
  else
    attrs['empty-token-sort'] = %w[C V P P][index - 8]
  end
  # Exercise secondary edges and free-form fields in graph visualizations.
  attrs['foreign-ids'] = 'synthetic=first' if index.zero?
  attrs['contrast-group'] = 'test-group' if index.zero?
  element('token', attrs, index == 2 ? element('slash', {'target-id' => 101, relation: 'pid'}) : nil)
end.join

def main_source(version, annotation, tokens)
  first_attrs = {id: 201, status: 'reviewed', 'presentation-after' => ' '}
  if version != '2.0'
    first_attrs.merge!({'annotated-by' => 'john', 'reviewed-by' => 'mary',
                       'annotated-at' => '2016-06-04T16:35:30+01:00', 'reviewed-at' => '2016-06-04T16:35:30+01:00'})
  end
  sentences = element('sentence', first_attrs, tokens)
  4.times do |index|
    sid = 202 + index
    words = ["Panel#{index + 1}", 'holds', "cube#{index + 1}"]
    extra = words.each_with_index.map do |word, position|
      tid = 121 + index * 3 + position
      element('token', {id: tid, form: word, lemma: word, 'part-of-speech' => position == 1 ? 'V-' : 'Nb',
                        morphology: position == 1 ? '3spia----i' : '-s---na--i',
                        'head-id' => position == 1 ? nil : tid + (1 - position), relation: position == 1 ? 'pred' : 'obj',
                        'citation-part' => "1.1.#{[index + 2, 4].min}", 'presentation-after' => position == 2 ? '. ' : ' '})
    end.join
    sentences += element('sentence', {id: sid, status: 'reviewed', 'presentation-after' => ' '}, extra)
  end
  div_attrs = version == '2.0' ? {} : {id: 1}
  source = element('source', {id: 'synthetic-a', language: 'lat'},
    '<title>Synthetic models</title><citation-part>Test.</citation-part><license>MIT</license>' +
    element('div', div_attrs, '<title>Synthetic section 1.1</title>' + sentences))
  document(version, annotation + source)
end
save_fixture('dummy-proiel-xml-2.0.xml', main_source('2.0', annotation, main_tokens))
save_fixture('dummy-proiel-xml-2.1.xml', main_source('2.1', annotation, main_tokens))

# Two independently identified sources with disjoint object IDs.
sources = %w[synthetic-a synthetic-b].each_with_index.map do |id, index|
  element('source', {id: id, language: 'lat'}, '<title>Test source</title><citation-part>Test.</citation-part><license>MIT</license>' +
    element('div', {}, '<title>Test section</title>' +
      element('sentence', {id: 301 + index, status: 'unannotated'}, element('token', {id: 401 + index, form: "unit#{index}", relation: 'pred'}))))
end.join
save_fixture('multiple-sources.xml', document('2.0', annotation + sources))

# Minimal files test version recognition, not corpus contents.
%w[2.0 2.1 3.0].each { |version| save_fixture("data/proielxml-#{version}-minimal.xml", document(version, '')) }
save_fixture('data/proielxml-invalid-version-minimal.xml', document('9.9', ''))
save_fixture('data/proielxml-no-version-minimal.xml', document(nil, ''))

# All dictionary sections are freshly constructed, including multiform slots,
# absent optional attributes, Unicode keys, repeated distribution, and frames.
refs = %w[test-alpha test-beta test-gamma test-delta]
dictionary_sources = element('sources', {}, refs.first(3).each_with_index.map { |id, index|
  element('source', {idref: id, license: index.zero? ? 'MIT' : nil, n: index.zero? ? 10 : nil})
}.join)
homographs = element('homographs', {}, %w[F- Ne].map { |pos| element('homograph', {lemma: 'ζο', 'part-of-speech' => pos}) }.join)
slots = %w[--pna----i 3siia----i 1spia----i 2spia----i 3spia----i 1ppia----i 2ppia----i 3ppia----i]
paradigm = element('paradigm', {}, slots.each_with_index.map { |morph, index|
  forms = if index == 0
            element('slot2', {form: 'lum-base', n: 1})
          elsif index == 1
            element('slot2', {form: 'lum-old', n: 3}) + element('slot2', {form: 'lum-alt', n: 1})
          else
            element('slot2', {form: "lum-#{index}", n: 1})
          end
  element('slot1', {morphology: morph}, forms)
}.join)
dictionary_frames = [[], [{relation: 'obj', case: 'a'}], [{relation: 'obl', case: 'b'}],
                     [{relation: 'comp', mood: 'n'}], [{relation: 'obj', case: 'd'}],
                     [{relation: 'xobj', mood: 'p'}], [{relation: 'arg'}]]
valency = element('valency', {}, dictionary_frames.each_with_index.map { |args, index|
  ids = index == 1 ? [801, 802, 803, 804] : [810 + index]
  element('frame', {}, element('arguments', {}, args.map { |arg| element('argument', arg) }.join) +
    element('tokens', {}, ids.map { |id| element('token', {idref: id, flags: 'a'}) }.join))
}.join)
dictionary = element('dictionary', {language: 'non', dialect: 'swe'}, dictionary_sources +
  element('lemmata', {}, element('lemma', {lemma: 'ζο', 'part-of-speech' => 'C-'}, homographs) +
    element('lemma', {lemma: 'lum', 'part-of-speech' => 'V-'},
      element('distribution', {}, refs.each_with_index.map { |id, index| element('source', {idref: id, n: index + 1}) }.join) +
      element('glosses', {}, element('gloss', {language: 'eng'}, 'illuminate') + element('gloss', {language: 'fra'}, 'illuminer')) +
      paradigm + valency)))

%w[2.0 2.1 3.0].each do |version|
  div_id = version == '2.0' ? {} : {id: 123}
  chronology = version == '3.0' ? '<chronology-composition>30 BC-20 BC</chronology-composition><chronology-manuscript>c. 1050</chronology-manuscript>' : ''
  source_attrs = {id: 'synthetic-a', language: version == '3.0' ? 'non' : 'lat'}
  source_attrs[:dialect] = 'swe' if version == '3.0'
  make_source = lambda do |token_attrs|
    element('source', source_attrs, '<title>Test skeleton</title><citation-part>Test.</citation-part><license>MIT</license>' + chronology +
      element('div', div_id, '<title>Test section</title>' +
        element('sentence', {id: 501, status: 'unannotated'}, element('token', {id: 601, form: 'node', relation: 'pred'}.merge(token_attrs)))))
  end
  body = annotation + make_source.call({}) + (version == '3.0' ? dictionary : '')
  save_fixture("data/proielxml-#{version}-skeleton.xml", document(version, body))
  next if version == '3.0'
  inconsistent = {'antecedent-id' => 999}
  inconsistent['alignment-id'] = 2 if version == '2.1'
  save_fixture("data/proielxml-#{version}-inconsistent.xml", document(version, annotation + make_source.call(inconsistent)))
end

# Twelve original *frame shapes*, not original annotated tokens or edges.
# New functor identifiers are ordered consistently to retain sorting coverage.
frame_shapes = [[], [{relation: 'obl', case: 'a'}], [{relation: 'obl', case: 'b'}],
  [{relation: 'obl', lemma: 'f-ab', part_of_speech: 'R-', case: 'b'}],
  [{relation: 'obl', lemma: 'f-ad', part_of_speech: 'R-', case: 'a'}],
  [{relation: 'obl', lemma: 'f-eo', part_of_speech: 'Df'}],
  [{relation: 'obl', lemma: 'f-ex', part_of_speech: 'R-', case: 'b'}],
  [{relation: 'obl', lemma: 'f-huc', part_of_speech: 'Df'}],
  [{relation: 'obl', lemma: 'f-in', part_of_speech: 'R-', case: 'a'}],
  [{relation: 'obl', lemma: 'f-ab', part_of_speech: 'R-', case: 'b'}, {relation: 'obl', lemma: 'f-ad', part_of_speech: 'R-', case: 'a'}],
  [{relation: 'obl', lemma: 'f-ex', part_of_speech: 'R-', case: 'b'}, {relation: 'obl', lemma: 'f-ad', part_of_speech: 'R-', case: 'a'}],
  [{relation: 'obl', lemma: 'f-ex', part_of_speech: 'R-', case: 'b'}, {relation: 'obl', lemma: 'f-in', part_of_speech: 'R-', case: 'a'}]]
valency_sentences = []
expected_frames = frame_shapes.each_with_index.map do |shape, index|
  # Two nonreflexive instances and one reflexive instance aggregate per shape.
  partitions = {a: [], r: []}
  3.times do |instance|
    base = 1000 + index * 100 + instance * 10
    partitions[instance == 2 ? :r : :a] << base
    tokens = element('token', {id: base, form: 'moves', lemma: 'synth-move', 'part-of-speech' => 'V-', morphology: '3spia----i', relation: 'pred'})
    shape.each_with_index do |arg, position|
      aid = base + 1 + position * 2
      attrs = {id: aid, form: "arg#{position}", lemma: arg[:lemma] || 'synth-noun', 'part-of-speech' => arg[:part_of_speech] || 'Nb',
               morphology: "-s---n#{arg[:case] || '-'}--i", 'head-id' => base, relation: arg[:relation]}
      tokens += element('token', attrs)
      if arg[:part_of_speech] == 'R-'
        tokens += element('token', {id: aid + 1, form: 'inner', lemma: 'synth-inner', 'part-of-speech' => 'Nb',
                                   morphology: "-s---n#{arg[:case]}--i", 'head-id' => aid, relation: 'obl'})
      end
    end
    if instance == 2
      tokens += element('token', {id: base + 8, form: 'self', lemma: 'synth-self', 'part-of-speech' => 'Pk', 'head-id' => base, relation: 'aux'})
    end
    valency_sentences << element('sentence', {id: base, status: 'reviewed'}, tokens)
  end
  {arguments: shape, tokens: partitions}
end
valency_source = element('source', {id: 'synthetic-valency', language: 'lat'},
  '<title>Synthetic valency</title><citation-part>Test.</citation-part><license>MIT</license>' +
  element('div', {}, '<title>Frames</title>' + valency_sentences.join))
save_fixture('synthetic-valency.xml', document('2.0', annotation + valency_source))

# Exact, fail-closed migrations for the pinned upstream tests.  No examples are
# removed or disabled; data-specific counts and strings follow the new fixtures.
def migrate(file)
  path = File.join('spec', file)
  original = File.read(path)
  changed = yield(original)
  File.write(path, changed)
end

def replace_once(text, pattern, replacement)
  count = text.scan(pattern).length
  abort "Pinned source mismatch: #{pattern.inspect} matched #{count} times" unless count == 1
  text.sub(pattern) { replacement }
end

%w[treebank_spec.rb source_spec.rb reader_spec.rb].each do |file|
  migrate(file) { |text| text.gsub('caes-gal', 'synthetic-a').gsub('cic-att', 'synthetic-b') }
end
%w[source_spec.rb div_spec.rb].each do |file|
  migrate(file) { |text| text.gsub('eql(119)', 'eql(24)').gsub('Caes. Gal.', 'Test.').gsub('Caes., Gall. 1.1', 'Synthetic section 1.1') }
end
migrate('treebank_spec.rb') { |text| text.gsub('680720', '101').gsub('52548', '201') }
migrate('token_spec.rb') do |text|
  text = text.gsub('Gallia', 'Orin').gsub('Caes. Gal.', 'Test.').gsub('680720', '101').gsub('680721', '102').gsub('680723', '104')
  text = text.gsub('733299', '109').gsub('733300', '110').gsub('to_a[21]', 'to_a[8]').gsub('to_a[22]', 'to_a[9]')
  text = replace_once(text, /expect\(token_est\.dependents\.map\(&:id\)\.sort\).*$/, 'expect(token_est.dependents.map(&:id).sort).to eq([101, 104, 112])')
  text = replace_once(text, /expect\(token_quarum\.ancestors\.map\(&:id\)\).*$/, 'expect(token_quarum.ancestors.map(&:id)).to eq([107, 106, 105, 104, 102])')
  text = replace_once(text, /expect\(token_est\.descendents\.map\(&:id\)\.sort\).*$/, 'expect(token_est.descendents.map(&:id).sort).to eq([101, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112])')
  text.gsub(/token_gallia/, 'token_orin').gsub(/token_est/, 'token_builds').gsub(/token_divisa/, 'token_models').gsub(/token_quarum/, 'token_lamps').gsub(/# id 680727/, '# id 108')
end
plain_first = 'Orin builds bright models beside quiet blue lamps.  '
formatted_first = '1Orin1 1builds1 1bright1 1models1 1beside1 1quiet1 1blue1 1lamps1.  '
plain_source = plain_first + (1..4).map { |index| "Panel#{index} holds cube#{index}.  " }.join
migrate('sentence_spec.rb') do |text|
  text = text.gsub('52548', '201').gsub('680721', '102').gsub('eq(26)', 'eq(12)').gsub('Caes. Gal.', 'Test.').gsub("# 'est' is the root", "# 'builds' is the root")
  text = replace_once(text, /expect\(sentence\.printable_form\)\.to eq\(.*\)$/, "expect(sentence.printable_form).to eq(#{plain_first.inspect})")
  replace_once(text, /expect\(sentence\.printable_form\(custom_token_formatter: formatter\)\).*$/, "expect(sentence.printable_form(custom_token_formatter: formatter)).to eq(#{formatted_first.inspect})")
end
%w[source div].each do |kind|
  migrate("#{kind}_spec.rb") do |text|
    replace_once(text, /expect\(#{kind}\.printable_form\)\.to eql\(.*\)$/, "expect(#{kind}.printable_form).to eql(#{plain_source.inspect})")
  end
end
migrate('annotation_schema_spec.rb') do |text|
  text.gsub('"adverbial"', '"Test relation adv"').gsub('"personal reflexive pronoun"', '"Test POS Pk"').gsub('"acc-inf"', '"Test status acc_inf"')
end
migrate('validation_spec.rb') { |text| text.gsub('1084259', '601') }
migrate('dictionary_builder_spec.rb') do |text|
  text = text.gsub('Gallia', 'Orin')
  text.gsub(/      # Sentence .*\n/, "      # Independently authored synthetic named token.\n").gsub(/      # Orin:.*\n/, '')
end
migrate('dictionary_spec.rb') do |text|
  {'afnik' => 'test-alpha', 'avv' => 'test-beta', 'birchbark' => 'test-gamma', 'suz-lav' => 'test-alpha',
   'CC SA-BY-NC 4.0' => 'MIT', 'благодарити' => 'lum', 'бл҃годарити' => 'lum-base',
   'бл҃годарѧше' => 'lum-old', 'бл҃годарꙗше' => 'lum-alt', 'thank' => 'illuminate',
   '2185961' => '801', '2188457' => '802', '2217926' => '803', '2160424' => '804'}.each { |old, new| text = text.gsub(old, new) }
  text.gsub("'а'", "'ζο'")
end

# Replace corpus-derived inline examples too: they embed full annotated source
# excerpts despite residing in a Ruby spec.  Fresh minimal graphs preserve
# coordinated-case collapse, prep-case hoisting, coordinated-subjunction mood
# hoisting, and exclusion of nonargument branches.
coordination_xml = element('sentence', {id: 901, status: 'reviewed'},
  element('token', {id: 901, form: 'packs', lemma: 'synth-pack', 'part-of-speech' => 'V-', relation: 'pred'}) +
  element('token', {id: 902, form: 'and', lemma: 'synth-and', 'part-of-speech' => 'C-', 'head-id' => 901, relation: 'obj'}) +
  element('token', {id: 903, form: 'box', 'part-of-speech' => 'Nb', morphology: '-s---na--i', 'head-id' => 902, relation: 'obj'}) +
  element('token', {id: 904, form: 'bag', 'part-of-speech' => 'Nb', morphology: '-s---fa--i', 'head-id' => 902, relation: 'obj'}) +
  element('token', {id: 905, form: 'also', 'part-of-speech' => 'Df', 'head-id' => 902, relation: 'aux'}) +
  element('token', {id: 906, form: 'helping', 'part-of-speech' => 'V-', morphology: '-sppamn-si', 'head-id' => 901, relation: 'xadv'}, element('slash', {'target-id' => 901, relation: 'xsub'})) +
  element('token', {id: 907, form: 'tool', 'part-of-speech' => 'Nb', morphology: '-s---na--i', 'head-id' => 906, relation: 'obj'}))
prep_xml = element('sentence', {id: 910, status: 'reviewed'},
  element('token', {id: 910, form: 'takes', 'part-of-speech' => 'V-', relation: 'pred'}) +
  element('token', {id: 911, form: 'from', lemma: 'synth-from', 'part-of-speech' => 'R-', 'head-id' => 910, relation: 'obl'}) +
  element('token', {id: 912, form: 'crate', 'part-of-speech' => 'Ne', morphology: '-s---nb--i', 'head-id' => 911, relation: 'obl'}))
mood_xml = element('sentence', {id: 920, status: 'reviewed'},
  element('token', {id: 920, form: 'asks', 'part-of-speech' => 'V-', relation: 'pred'}) +
  element('token', {id: 921, form: 'from', lemma: 'synth-from', 'part-of-speech' => 'R-', 'head-id' => 920, relation: 'obl'}) +
  element('token', {id: 922, form: 'unit', 'part-of-speech' => 'Pp', morphology: '3s---nb--i', 'head-id' => 921, relation: 'obl'}) +
  element('token', {id: 923, 'empty-token-sort' => 'P', 'head-id' => 920, relation: 'sub'}) +
  element('token', {id: 924, form: 'that', lemma: 'synth-that', 'part-of-speech' => 'G-', 'head-id' => 920, relation: 'comp'}) +
  element('token', {id: 925, form: 'and', 'part-of-speech' => 'C-', 'head-id' => 924, relation: 'pred'}) +
  element('token', {id: 926, form: 'shine', 'part-of-speech' => 'V-', morphology: '3spsa----i', 'head-id' => 925, relation: 'pred'}) +
  element('token', {id: 927, form: 'glow', 'part-of-speech' => 'V-', morphology: '3pisa----i', 'head-id' => 925, relation: 'pred'}) +
  element('token', {id: 928, form: 'auxiliary', 'part-of-speech' => 'Df', 'head-id' => 925, relation: 'aux'}) +
  element('token', {id: 929, form: 'other', 'part-of-speech' => 'Nb', morphology: '-s---na--i', 'head-id' => 927, relation: 'obj'}))
migrate('valency_spec.rb') do |text|
  replacement = <<~SPEC
    describe PROIEL::Valency do
      it 'aggregates twelve argument frames and partitions reflexive predicates' do
        tb = PROIEL::Treebank.new
        tb.load_from_xml(test_file('synthetic-valency.xml'))
        lexicon = PROIEL::Valency::Lexicon.new
        tb.sources.each { |source| lexicon.add_source!(source) }
        expect(lexicon.lookup('synth-move', 'V-')).to eq #{expected_frames.inspect}
      end

      it 'identifies two coordinated nominal objects with the same case as a single object' do
        t = MockXMLIO.mock_token_in_sentence(#{coordination_xml.inspect}, 901)
        expect(PROIEL::Valency::Arguments.get_argument_frame(t)).to eq [{relation: 'obj', case: 'a'}]
      end

      it 'hoists the case of a dependent of a preposition' do
        t = MockXMLIO.mock_token_in_sentence(#{prep_xml.inspect}, 910)
        expect(PROIEL::Valency::Arguments.get_argument_frame(t)).to eq [{relation: 'obl', lemma: 'synth-from', part_of_speech: 'R-', case: 'b'}]
      end

      it 'hoists the mood of coordinated dependents of a subjunction' do
        t = MockXMLIO.mock_token_in_sentence(#{mood_xml.inspect}, 920)
        expect(PROIEL::Valency::Arguments.get_argument_frame(t)).to eq [
          {relation: 'obl', lemma: 'synth-from', part_of_speech: 'R-', case: 'b'},
          {relation: 'comp', lemma: 'synth-that', part_of_speech: 'G-', mood: 's'}]
      end
    end
  SPEC
  abort 'Origin must strip corpus-derived valency examples' if text.include?('describe PROIEL::Valency do')
  text + replacement
end
