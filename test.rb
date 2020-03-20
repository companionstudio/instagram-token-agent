a='aisle.department.shop.city.country'
# hash = {}.tap do |h|
#   a.split('.').each do |model|
#     h[model] = '...'
#     # h[model] = model.classify.constantize.reflections.keys
#   end
# end

# a.split('.').reverse.reduce({}) do |a, v|
#   if a.empty?
#     a[v] = '...'
#   else
#     a = {v => ['...', a]}
#   end
#   a
# end

p = a.split('.').reverse.reduce({}) do |a, v|
  a.empty? ? {v => '...'} : {v => ['...', a]}
end

puts p.inspect
