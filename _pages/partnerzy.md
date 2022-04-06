---
layout: page
title: Partnerzy / Sponsorzy
permalink: /partnerzy
comments: false
image: 
imageshadow: true
---

<div class="list-authors mt-5">
{% for partner in site.partners %}   
    <div id="{{ partner[1].name }}" class="authorbox position-relative pb-5 pt-5 mb-4 mt-4 border">   
        <div class="row">
            <div class="wrapavname col-md-4 text-center">
                {% if partner[1].logo %}
                <img  class="partner-thumb" src="{{site.baseurl}}/{{ partner[1].logo }}" title="{{ partner[1].display_name }}" alt="{{ partner[1].display_name }}">
                {% endif %}

                <p class="mt-4 mb-0 small text-center">

                    {% if partner[1].web %}
                        <a target="_blank" class="d-inline-block mx-1 text-dark" href="{{ partner[1].web }}" rel="nofollow" title="{{ partner[1].display_name }}"><i class="fa fa-link"></i></a> 
                    {% endif %}

                    {% if partner[1].twitter %}
                        <a target="_blank" class="d-inline-block mx-1 text-dark" href="{{ partner[1].twitter }}"><i class="fab fa-twitter"></i></a>
                    {% endif %}

                    {% if partner[1].email %}
                        <a class="d-inline-block mx-1 text-dark" href="mailto:{{ partner[1].email }}"><i class="fa fa-envelope"></i></a>
                    {% endif %}

                </p>
                
            </div>
            <div class="col-md-8 text-center">
                <h3>{{ partner[1].display_name }}</h3>
                <p class="mt-3 mb-0">{{ partner[1].description }}</p> 
            </div>
        </div> 
    </div>    
{% endfor %}
</div>
