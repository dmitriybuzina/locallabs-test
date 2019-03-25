require 'mysql2'


class Scraper
  def initialize
    @client = Mysql2::Client.new(host: '', username: '', password: '', database: '')
  end

  def insert(id, clean_name, sentence)
    @client.query("Update base
                       Set clean_name = \"#{clean_name}\", sentence = \"#{sentence}\"
                       Where id = \"#{id}\";")
  end

  def select
    @client.query("SELECT * FROM Applicant_tests.base;")
  end

  def main
    select.each do |result|
      @str = result["candidate_office_name"]
      run
      clean_name = @str
      puts result['id']
      sentence = "The candidate is running for the #{clean_name} office."
      insert(result['id'], clean_name, sentence)
    end
  end

  def run
    twp if @str.include? 'Twp'
    hwy if @str.include? 'Hwy'
    delete_periods if @str.include? '.'
    slashes
    delete_duplicate
  end

  def twp
    @str = @str.gsub('Twp', 'Township')
  end

  def hwy
    @str = @str.gsub('Hwy', 'Highway')
  end

  def delete_periods
    @str = @str.tr('.', '') if @str.index('.') == @str.length - 1
  end

  def delete_duplicate
    @str = @str.split.uniq(&:capitalize).join(' ')
  end

  def slashes
    return if @str.length.zero?

    tokens = @str.split(/\//)
    tokens = to_parentheses(tokens)
    if tokens.length > 1
      @str = ''
      tokens = tokens.unshift(tokens.pop)
      tokens.delete('')
      tokens.each_with_index do |elem, index|
        @str += case index
                when 0
                  elem
                when 1
                  elem.include?('(') ? ' ' + elem : ' ' + elem.downcase
                else
                  ' and ' + elem.downcase
                end
      end
    else
      @str = tokens[0].include?('(') ? tokens[0] : tokens[0].downcase
    end
  end

  def to_parentheses(tokens)
    tokens.map do |el|
      if el =~ /.+,.+/
        e = el.split(',')
        e[0].downcase + ' (' + e[1].lstrip + ')'
      else
        el
      end
    end
  end
end

scraper = Scraper.new
scraper.main