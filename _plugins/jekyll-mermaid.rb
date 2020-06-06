
require 'pry'

module Jekyll
  module Tags
    class Mermaid < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
      end

      def render(context)
        @config = context.registers[:site].config['mermaid']
        "<div class=\"mermaid\">#{super.strip}</div>"
      end
    end
  end
end

Liquid::Template.register_tag('mermaid', Jekyll::Tags::Mermaid)
