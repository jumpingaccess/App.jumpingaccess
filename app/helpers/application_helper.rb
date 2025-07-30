module ApplicationHelper
  def country_options
    ISO3166::Country.all.map do |c|
      name =
        c.translations&.fetch('fr', nil) ||
        c.common_name ||
        c.name ||
        c.alpha2

      [name, c.alpha2]
    end.sort_by(&:first).uniq
  end
  def country_name_from_code(code)
    country = ISO3166::Country[code]
    country&.translations&.fetch('fr', nil) || country&.name || code
  end
end