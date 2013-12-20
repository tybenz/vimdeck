# VIMDECK

## PURE AWESOME


# VIM ROCKS!

![](img/vim.png)


## PARAGRAPHS

This is a `paragraph` (plain text)

This is another paragraph


## NUMBERED LIST

1. This _is_ how a *numbered* list
2. Looks in **vimdeck**
3. What do ***you*** think?


# BULLETS

• First{~
• Second
• Third~}


# BULLETS

{~• First~}
• Second{~
• Third~}


# BULLETS

{~• First
• Second~}
• Third


## CODE

```ruby
module Parts
  class foo
    def slide
     "of a"
    end

    def can
      highlight = "vimdeck"
    end
  end
end
```


## CODE

```ruby
{~module Parts
  class foo
    def slide
     "of a"
    end

    def can
      highlight = ~}"vimdeck"{~
    end
  end
end~}
```


## CODE

```ruby
{~module Parts
  class foo
    def slide
     "of a"
    end

    def~} can
      {~highlight = "vimdeck"
    end
  end
end~}
```


## CODE

```ruby
{~module Parts
  class foo
    def slide
     "of a"
    end

    def can~}
      highlight {~= "vimdeck"
    end
  end
end~}
```


## CODE

```ruby
{~module~} Parts
  {~class foo
    def slide
     "of a"
    end

    def can
      highlight = "vimdeck"
    end
  end
end~}
```


## CODE

```ruby
{~module Parts
  class foo
    def slide~}
     "of a"
    {~end

    def can
      highlight = "vimdeck"
    end
  end
end~}
```


## CODE

```ruby
{~module Parts
  class foo
    def~} slide
     {~"of a"
    end

    def can
      highlight = "vimdeck"
    end
  end
end~}
```


## CODE PT 2

```javascript
(function( window, $, undefined ) {
    $( '.hello' ).on( 'click', function sayHello() {
        alert( 'Why, hello there!' );
    });
})( window, jQuery );
```

```html
<body>
    <a href="#" class="hello">Hello!</a>
</body>
```


## CODE PT 2

```javascript
{~(function( window, $, undefined ) {
    $( '.hello' ).on( 'click', function sayHello() {~}
        alert( 'Why, hello there!' );{~
    });
})( window, jQuery );~}
```

```html
<body>
    <a href="#" class="hello">Hello!</a>
</body>
```


## CODE PT 2

```javascript
(function( window, $, undefined ) {
    $( '.hello' ).on( 'click', function sayHello() {
        alert( 'Why, hello there!' );
    });
})( window, jQuery );
```

```html
{~<body>~}
    <a href="#" class="hello">Hello!</a>
{~</body>~}
```


## CODE PT 2

```javascript
{~(function( window, $, undefined ) {
    $( '.hello' ).on( 'click', function sayHello() {~}
        alert( 'Why, hello there!' );{~
    });
})( window, jQuery );
```

```html
<body>
    <a href="#" class="hello">Hello!</a>
</body>~}
```


# The End!
