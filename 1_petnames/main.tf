locals {
  # Show the top N results
  top_n = 5

  # Load petnames file as an array of names, pruning empty names
  pet_names = compact(split("\n", file("petnames.txt")))

  # Generate the initials for each name
  all_initials = [
    for name in local.pet_names: join(
      "",
      [ for word in split("-", name): split("", word)[0] ]
    )
  ]

  ################
  # Top N most common initials
  ################

  # Group initials into a list of counts (["abc","abc","def"] becomes {"abc" = [1,1], "def" = [1]})
  grouped_initials   = { for initials in local.all_initials: initials => 1 ... }
  # Replace lists from above with their length ({"abc" = [1,1]} becomes {"abc" = 2})
  counts_by_initials = { for initials, ones in local.grouped_initials : initials => length(ones) }

  # Find the length in characters of the largest count (999 would be 3, 1000 would be 4)
  max_count_length = length(tostring(max(values(local.counts_by_initials)...)))

  # 0-pad all counts to the length of the largest count and append with the initials ("039=abc")
  #
  # sort() only works on strings and doesn't have a numeric sort option.  0-padding makes a string
  # sort work the same as a numeric sort and appending the initials keeps the count and initials
  # paired since sort won't work on maps or lists of maps
  combined_counts = [
    for initials, count in local.counts_by_initials: (
      format("%0${local.max_count_length}d=%s", count, initials)
    )
  ]

  # Reverse sort so that the largest counts come first
  combined_counts_sorted = reverse(sort(local.combined_counts))

  # Grab just the top N counts
  top_n_counts = [ for n in range(0, local.top_n): local.combined_counts_sorted[n] ]

  # Create result string with pretty spacing
  top_n_result = join(
    "\n",
    [
      for count in local.top_n_counts: format(
        "%s: %${local.max_count_length}d",
        split("=", count)[1], # initials
        split("=", count)[0], # count
      )
    ]
  )

  seen_initials = length(local.counts_by_initials)
  unseen_initials = pow(26,3) - local.seen_initials

  # list of 0's for each of the possible initials that were not in the data set
  # range() can't handle numbers this big, but format() can
  unseen_initials_counts = split("", format("%0${local.unseen_initials}d", "0"))

  # counts for each of the possible initials
  counts = concat(local.unseen_initials_counts, values(local.counts_by_initials))
  max_count = max(local.counts...)

  ################
  # Histogram object with fixed bucket size
  ################

  histogram_bucket_size = 100
  histogram_largest_bucket = ceil(local.max_count / local.histogram_bucket_size) * local.histogram_bucket_size
  histogram = {
    for bucket in range(0, local.histogram_largest_bucket, local.histogram_bucket_size): format("%0${local.max_count_length}d", bucket) => (
      length(
        [
          for count in local.counts : count if (
            count >= bucket &&
            count < (bucket + local.histogram_bucket_size)
          )
        ]
      )
    )
  }
  ################
  # ASCII Histogram with dynamic bucket size
  ################

  rows = var.rows

  # The output is a heredoc indented 8 spaces
  unusable_cols = 8

  ascii_histogram_bucket_size = ceil(local.max_count / local.rows)

  ascii_histogram_largest_bucket = ceil(local.max_count / local.ascii_histogram_bucket_size) * local.ascii_histogram_bucket_size

  ascii_histogram_data = [
    for bucket in range(0, local.ascii_histogram_largest_bucket, local.ascii_histogram_bucket_size): {
      range_min = bucket
      range_max = bucket + local.ascii_histogram_bucket_size
      count = length(
        [
          for count in local.counts : count if (
            count >= bucket &&
            count < (bucket + local.ascii_histogram_bucket_size)
          )
        ]
      )
    }
  ]

  ascii_histogram_max_count = max(local.ascii_histogram_data.*.count...)

  # Remove unusable columns and length of the longest line's formatting characters so that a bar of length `local.cols` will go to the end of the screen
  cols = var.cols - local.unusable_cols - length("${local.ascii_histogram_largest_bucket} - ${local.ascii_histogram_largest_bucket}:  (${local.ascii_histogram_max_count})")

  # Length of characters of the largest bucket
  ascii_histogram_largest_bucket_length = length(tostring(local.ascii_histogram_largest_bucket))

  # Scaling factor to make lines fit on screen
  ascii_histogram_scaling_factor = local.cols / local.ascii_histogram_max_count

  ascii_histogram = join("",[
    for bucket in local.ascii_histogram_data: <<-EOT
      ${format("%${local.ascii_histogram_largest_bucket_length}d - %${local.ascii_histogram_largest_bucket_length}d", bucket.range_min, bucket.range_max)}: ${join("", [ for pixel in range(0,bucket.count * local.ascii_histogram_scaling_factor) : "#"])} (${bucket.count})
    EOT
  ])
}
