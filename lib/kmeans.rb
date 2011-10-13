module PdfExtract
  module Kmeans

    def self.take_keys item, keys
      r = {}
      keys.each do |key|
        r[key] = item[key]
      end
      r
    end

    def self.ndist a, b, keys
      sum = 0
      keys.each do |key|
        sum += (a[key] - b[key]) ** 2
      end
      Math.sqrt sum
    end

    def self.cluster_centre cluster
      keys = cluster[:centre].keys

      centre = {}

      # Sum each key
      cluster[:items].each do |item|
        keys.each do |key|
          centre[key] ||= 0
          centre[key] += item[key]
        end
      end

      # Avg each key
      centre.each_key do |key|
        centre[key] = centre[key] / cluster[:items].length.to_f
      end

      centre
    end
  
    def self.clusters items, keys, options = {}
      options = {
        :k => 10,
        :delta => 0.001,
        :init => [],
        :random => true
      }.merge options
      
      cs = []

      if not options[:init].empty?
        options[:init].each do |centre|
          cs << {:centre => centre, :items => []}
        end
      end
      
      # Make k clusters with random centre points
      if options[:random]
        options[:k].times do
          idx = (items.length * rand).to_i
          cs << {:centre => take_keys(items[idx], keys), :items => []}
        end
      end

      puts cs

      while true
        
        # Add each item to a cluster
        items.each do |item|
          min_distance = Float::MAX
          selected_cluster = nil

          cs.each do |cluster|
            distance = ndist(item, cluster[:centre], keys)
            if distance < min_distance
              min_distance = distance
              selected_cluster = cluster
            end
          end

          selected_cluster[:items] << item
        end

        # Drop clusters with no items (often because of duplicate
        # initial centre points)
        cs = cs.reject { |cluster| cluster[:items].empty? }

        max_delta = Float::MIN

        # Recalculate centre points and max delta
        cs.each do |cluster|
          old_centre = cluster[:centre]
          centre = cluster_centre cluster
          cluster[:centre] = centre

          max_delta = [ndist(old_centre, centre, keys), max_delta].max
        end
        
        if max_delta <= options[:delta]
          break
        else
          cs.each do |cluster|
            cluster[:items] = []
          end
        end
       
      end

      cs
    end

  end
end
