module Haml::Helpers
  def link_to_q n, title
    %{<a href="/#{@q.hash}/q#{"%03d"%n}">#{title}</a>}
  end

  def form_for_q n, &b
    inner_html = capture_haml(&b).chomp
    %{<form name="q#{"%03d"%n}" action="/#{@q.hash}/q#{"%03d"%n}" method="post">\n
#{inner_html}\n
</form>\n}
  end

  def ask(q)
    %{#{haml("%p.question #{q}", :layout => false).chomp}\n}
  end

  def submit
    haml("%p.submit\n  %input{ :type => 'submit', :value => 'következő &raquo;' }\n", :layout => false).chomp + "\n"
  end
end
