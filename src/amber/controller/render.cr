module Amber::Controller
  module Render
    LAYOUT = "application.slang"

    protected def render_text(body, status_code = 200)
      context.response.status_code = status_code
      context.response.content_type = "text/plain"
      context.content = body
    end

    protected def render_json(body, status_code = 200)
      context.response.status_code = status_code
      context.response.content_type = "text/json"
      context.content = body
    end

    protected def render_html(body, status_code = 200)
      context.response.status_code = status_code
      context.response.content_type = "text/html"
      context.content = body
    end

    macro render(template = nil, layout = true, partial = nil, path = "src/views", folder = __FILE__)
      {% if !(template || partial) %}
        raise "Template or partial required!"
      {% end %}

      {{filename = template || partial}}

      {% if filename.id.split("/").size > 1 %}
        %content = render_template("#{{{filename}}}", {{path}})
      {% else %}
        {% if folder.id.ends_with?(".ecr") %}
          %content = render_template("#{{{folder.split("/")[-2]}}}/#{{{filename}}}", {{path}})
        {% else %}
          %content = render_template("#{{{folder.split("/").last.gsub(/\_controller\.cr|\.cr/, "")}}}/#{{{filename}}}", {{path}})
        {% end %}
      {% end %}

      {% if layout && !partial %}
        content = %content
        render_template("layouts/#{{{layout.class_name == "StringLiteral" ? layout : LAYOUT}}}", {{path}})
      {% else %}
        %content
      {% end %}
    end

    private macro render_template(filename, path = "src/views")
    {% if filename.id.split("/").size > 2 %}
      Kilt.render("{{filename.id}}")
    {% else %}
      Kilt.render("#{{{path}}}/{{filename.id}}")
    {% end %}
  end
end
end
