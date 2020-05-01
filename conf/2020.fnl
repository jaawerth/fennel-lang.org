(local html (require :html))
(local style (require :conf.style))

(-> [:html {:lang "en"}
     [:head {} [:title {} "FennelConf 2020"]
      (unpack style)]
     [:body {}
      [:h1 {} "FennelConf 2020"]
      [:p {} [:b {} "Location:"] "Portland, OR, probably?"]
      [:p {} [:b {} "Time:"] "???"]
      [:p {} "Well, it was going to be in spring of 2020 but ..."
       " we'll need a little more time to figure out the details now."]
      [:hr {}]
      [:p {} "The "
       [:a {:href
            "https://github.com/bakpakin/Fennel/blob/master/CODE-OF-CONDUCT.md"}
        "code of conduct"] " for Fennel applies at FennelConf."]
      [:p {} [:a {:href (.. "https://git.sr.ht/~technomancy/fennel-lang.org/"
                            "tree/master/conf/2020.fnl"
                            )}
              "source"]]]]
    (html)
    (print))
