output "_1_petnames_read" {
  description = "Number of petnames read"
  value = length(local.pet_names)
}

output "_2_unique_initials" {
  description = "Number of unique initials found in file"
  value = local.seen_initials
}

output "_3_unseen_initials" {
  description = "Number possible initials that were not found in the file"
  value = local.unseen_initials
}

output "_4_top_5_most_common" {
  description = "The top 5 most common initials"
  value = local.top_n_result
}

output "_5_histogram" {
  description = "A Histogram showing the distribution of repeatd initials by number of repeats."
  value = local.histogram
}

output "_6_top_5_most_common" {
  description = "ASCII representation of _5_histogram"
  value = local.ascii_histogram
}
