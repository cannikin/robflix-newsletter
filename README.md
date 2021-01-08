# Robflix Newsletter

Aggregates new content added to Plex in the 7 days or so and sends a newsletter to users.

![image](https://user-images.githubusercontent.com/300/104048036-7d5b9e80-5197-11eb-9c55-bad8bd6a37d3.png)

## MOTD

To set a specific message at the top, add it to the `motd` file. It will be used on the next send and then cleared out so that it returns to the default header for the next send.

MOTD format is plain HTML. It can use the following variables (in addition any `ENV` vars that may be present) to insert some additional data:

* `total_movie_count`
* `total_tv_count`
* `recent_count`

The default MOTD is:

```html
<h1>Hello Robflix Subscribers!</h1>
<h2>Here's <%= recent_count %> of the movies/shows added in the past week.</h2>
<p>
  Robflix is big (<%= total_movie_count %> movies and <%= total_tv_count %> TV shows) but we don't have everything. Yet. If you want to help expand the Robflix library you can pick up something from the <a href="<%= ENV['WISHLIST_LINK'] %>">Robflix Wishlist</a>! (And you can add to it if there's something you want to see.)
</p>
```

## Testing

    DEBUG=1 ruby ./runner.rb
    
Writes newsletter content out to index.html file in home directory.

    DEBUG=1 SEND=1 ruby ./runner.rb
    
Sends a real email but only to my Gmail account.

## Sending for Real

    SEND=1 ruby ./runner.rb
    
Pulls the live list of users from Plex and sends to each.
