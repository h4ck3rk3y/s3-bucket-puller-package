# s3-bucket-puller

This package is a library package that shows you how to pull in s3 buckets into Kurtosis persistent directories.

Look at the `main.star` for usage while the actual library lives in `lib.star`.

For Kubernetes we highly recommend passing `node_selectors` which is available in Kurtosis > 0.86.17. We recommend
0.86.18 instead as the 0.86.17 node selector is aggressive on validating labels.
