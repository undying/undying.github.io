---
layout: post
title: "How to cleanup FS metadata from partition"
date: 2016-01-28 02:58:00 +0300
tags: fs raid hdd
---

Sometimes you I'm need to create new FS on partition, which was already used for something else (another FS, RAID, LVM).
I was wondering about most usable ways to clear metadata. Here is some I liked the most.

<b>first</b>
{% highlight bash %}
wipefs -a ${DEVICE}
{% endhighlight %}

<b>second</b>
{% highlight bash %}
dd if=/dev/zero of=${DEVICE} bs=512 seek=$(( $(blockdev --getsz ${DEVICE}) - 1024 )) count=1024
{% endhighlight %}

<b>third</b>
{% highlight bash %}
dmraid -r -E ${DEVICE}
{% endhighlight %}

This is not all the ways, but for me the most easy usable (except dd, in this case).

