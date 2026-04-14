module RedmineRedsun
  module Helper
    class Text
      def self.convert_textile_with_tables(content)
        # Tabellen in strukturierten Text umwandeln
        content = content.gsub(/\|(.+?)\|/) do |match|
          cells = match.scan(/\|([^|]+)/).flatten
          cells.map(&:strip).join(' ')
        end

        # Dann normale Textile-Konvertierung
        textile_to_plain_text(content)
      end
    end
  end
end