require "test/unit"
require "rexml/document"
 
class TestOutput < Test::Unit::TestCase
  
  def setup
    @expected_code = 'MPHG'
    @expected_version = '0.9.9'
    @expected_folder = @expected_code + '-v' + @expected_version
    
    @xml = File.new( "#{@expected_folder}/#{@expected_code}.xml" )
    @doc = REXML::Document.new( @xml )
  end
 
  def teardown
    
  end
 
  def test_folder_structure    
    assert File.directory?( @expected_folder )
    assert File.directory?( "#{@expected_folder}/_rels" )
    assert File.directory?( "#{@expected_folder}/cards" )
  end
 
  def test_files    
    assert File.exists?( "#{@expected_folder}/[Content_Types].xml" )
    assert File.exists?( "#{@expected_folder}/#{@expected_code}.xml" )
    assert File.exists?( "#{@expected_folder}/_rels/.rels" )
    assert File.exists?( "#{@expected_folder}/_rels/#{@expected_code}.xml.rels" )
    assert_equal 38, Dir.glob("#{@expected_folder}/cards/*").length
  end
 
  def test_setname    
    assert_equal "Monty Python and the Holy Grail deck", @doc.get_elements('set')[0].attribute("name").to_s
  end
 
  def test_version    
    assert_equal @expected_version, @doc.get_elements('set')[0].attribute("version").to_s
  end
 
  def test_uuid  
    assert_equal '645f7468-655f-686f-6c79-5f677261696c', @doc.get_elements('set')[0].attribute("id").to_s
  end
 
  def test_numcards
    assert_equal 38, @doc.get_elements('set/cards/card').length
  end
 
end