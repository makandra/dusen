reload!; Benchmark.measure { puts "..."; Note.search('rails test method').all; puts "DONE." }









reload!

site = Site.first
note_scope = site.notes; nil
note_ids = note_scope.collect_ids; nil
puts "Benchmarking #{note_ids.size} notes"

batch_size = 1000
amount = batch_size
max_amount = note_ids.size

while amount < max_amount

  batch_ids = note_ids[0, amount]
  batch_scope = note_scope.scoped(:conditions => { :id => batch_ids })
  
  times = []
  25.times do
    times << (Benchmark.realtime { batch_scope.search('rails test method').count })
  end
  
  time = times.sum.to_f / times.size
  
  puts "#{amount}; #{time}"

  amount += batch_size

end


#------------------------------------------


reload!

Note.delete_all('site_id <> 1')

batch_size = 1000
amount = 20000

while Note.count >= batch_size

  while Note.count > amount
    Note.last.destroy
  end

  times = []
  25.times do
    times << (Benchmark.realtime { Note.search('rails test method').count })
  end
  
  time = times.sum.to_f / times.size
  
  puts "#{amount}; #{time}"

  amount -= batch_size

end


