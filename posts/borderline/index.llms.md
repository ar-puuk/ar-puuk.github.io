I spend my days around maps of the U.S., which makes it a little embarrassing how often I cannot place a county. Borderline is the fix: you are given a place name, you click where you think it is on a black outline map, and you find out how close to “borderline” your geography really is.

It is a small game, but it turned out to be a good excuse to deal with some real cartography problems in plain JavaScript: which projection to draw a single state in, how to tell whether a click landed inside a county with a coastline full of islands, and how to keep an offline web app from serving stale code forever.

## 1 Play

Borderline

Fullscreen

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbi1kZWZzIiBhcmlhLWhpZGRlbj0idHJ1ZSI+CiAgPGRlZnM+CiAgICA8c3ltYm9sIGlkPSJpY29uLXBpbiIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPHBhdGggZD0iTTEyIDIxLjVzLTcuMi02LjQtNy4yLTExLjVhNy4yIDcuMiAwIDEgMSAxNC40IDBjMCA1LjEtNy4yIDExLjUtNy4yIDExLjV6IiAvPgogICAgICA8Y2lyY2xlIGN4PSIxMiIgY3k9IjEwIiByPSIyLjYiPjwvY2lyY2xlPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWdyaWQiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxyZWN0IHg9IjMiIHk9IjMiIHdpZHRoPSI3LjUiIGhlaWdodD0iNy41IiByeD0iMS40IiAvPgogICAgICA8cmVjdCB4PSIxMy41IiB5PSIzIiB3aWR0aD0iNy41IiBoZWlnaHQ9IjcuNSIgcng9IjEuNCIgLz4KICAgICAgPHJlY3QgeD0iMyIgeT0iMTMuNSIgd2lkdGg9IjcuNSIgaGVpZ2h0PSI3LjUiIHJ4PSIxLjQiIC8+CiAgICAgIDxyZWN0IHg9IjEzLjUiIHk9IjEzLjUiIHdpZHRoPSI3LjUiIGhlaWdodD0iNy41IiByeD0iMS40IiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWxlYWYiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik01IDIxYzAtOC41IDQuMi0xNiAxNS0xNiAwIDEwLjYtOC41IDE0LjktMTUgMTZ6IiAvPgogICAgICA8cGF0aCBkPSJNNS41IDIwLjVDNy43IDE1LjggMTEgMTIuMyAxNS41IDEwIiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWZsYW1lIiB2aWV3Ym94PSIwIDAgMjQgMjQiPgogICAgICA8cGF0aCBkPSJNMTIgMjIuNWM0LjQgMCA3LjUtMi45IDcuNS03LjQgMC0zLjItMS43LTUuNC0zLjItNy41LjMgMi4yLTEgMy4zLTIgMy4zLjgtMy4zLTEuMS02LjUtNC4xLTguNy41IDMuMi0xLjIgNS40LTMuMSA3LjUtMS40IDEuNS0yLjEgMy4yLTIuMSA1LjQgMCA0LjUgMy4xIDcuNCA2LjkgNy40eiIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi10cm9waHkiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik04IDQuNWg4djRhNCA0IDAgMCAxLTggMHYtNHoiIC8+CiAgICAgIDxwYXRoIGQ9Ik04IDUuNUg1LjJBMy4zIDMuMyAwIDAgMCA4IDguNiIgLz4KICAgICAgPHBhdGggZD0iTTE2IDUuNWgyLjhBMy4zIDMuMyAwIDAgMSAxNiA4LjYiIC8+CiAgICAgIDxwYXRoIGQ9Ik0xMC4yIDE1aDMuNnYyaC0zLjZ6IiAvPgogICAgICA8cGF0aCBkPSJNOCAyMWg4IiAvPgogICAgICA8cGF0aCBkPSJNMTIgMTd2NCIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi1mbGFnIiB2aWV3Ym94PSIwIDAgMjQgMjQiPgogICAgICA8cGF0aCBkPSJNNS41IDIxLjVWMy44IiAvPgogICAgICA8cGF0aCBkPSJNNS41IDQuM2gxM2wtMy4yIDQuMiAzLjIgNC4yaC0xMyIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi16YXAiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik0xMy4yIDIgNC41IDE0aDUuOGwtMSA4IDktMTIuM2gtNS44bDEtNy43eiIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi1jbG9jayIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iOS4yIj48L2NpcmNsZT4KICAgICAgPHBhdGggZD0iTTEyIDYuOFYxMmwzLjYgMi4xIiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWNoZWNrLWNpcmNsZSIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iOS4yIj48L2NpcmNsZT4KICAgICAgPHBhdGggZD0iTTcuOCAxMi40bDIuNiAyLjYgNS44LTYuMyIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi14LWNpcmNsZSIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iOS4yIj48L2NpcmNsZT4KICAgICAgPHBhdGggZD0iTTkgOWw2IDZNMTUgOWwtNiA2IiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWFycm93LWxlZnQiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik0xOSAxMkg1IiAvPgogICAgICA8cGF0aCBkPSJNMTEgNmwtNiA2IDYgNiIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi1hcnJvdy1yaWdodCIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPHBhdGggZD0iTTUgMTJoMTQiIC8+CiAgICAgIDxwYXRoIGQ9Ik0xMyA2bDYgNi02IDYiIC8+CiAgICA8L3N5bWJvbD4KICAgIDxzeW1ib2wgaWQ9Imljb24tcmVmcmVzaCIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPHBhdGggZD0iTTQgMTJhOCA4IDAgMCAxIDEzLjYtNS43TDIwIDguNSIgLz4KICAgICAgPHBhdGggZD0iTTIwIDR2NC41aC00LjUiIC8+CiAgICAgIDxwYXRoIGQ9Ik0yMCAxMmE4IDggMCAwIDEtMTMuNiA1LjdMNCAxNS41IiAvPgogICAgICA8cGF0aCBkPSJNNCAyMHYtNC41aDQuNSIgLz4KICAgIDwvc3ltYm9sPgogICAgPHN5bWJvbCBpZD0iaWNvbi1zbGlkZXJzIiB2aWV3Ym94PSIwIDAgMjQgMjQiPgogICAgICA8cGF0aCBkPSJNNCA2aDlNMTcgNmgzTTQgMThoM00xMSAxOGg5IiAvPgogICAgICA8Y2lyY2xlIGN4PSIxNC41IiBjeT0iNiIgcj0iMi4yIj48L2NpcmNsZT4KICAgICAgPGNpcmNsZSBjeD0iOCIgY3k9IjE4IiByPSIyLjIiPjwvY2lyY2xlPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLXN1biIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iNC4zIj48L2NpcmNsZT4KICAgICAgPHBhdGggZD0iTTEyIDIuNnYyLjNNMTIgMTkuMXYyLjNNNC4zIDQuM2wxLjYgMS42TTE4LjEgMTguMWwxLjYgMS42TTIuNiAxMmgyLjNNMTkuMSAxMmgyLjNNNC4zIDE5LjdsMS42LTEuNk0xOC4xIDUuOWwxLjYtMS42IiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLW1vb24iIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik0yMCAxNC4zQTguNCA4LjQgMCAxIDEgOS43IDRhNyA3IDAgMCAwIDEwLjMgMTAuM3oiIC8+CiAgICA8L3N5bWJvbD4KICAgIDxzeW1ib2wgaWQ9Imljb24tZ2l0aHViIiB2aWV3Ym94PSIwIDAgMjQgMjQiIGZpbGw9ImN1cnJlbnRDb2xvciIgc3Ryb2tlPSJub25lIj4KICAgICAgPHBhdGggZD0iTTEyIC4zQzUuNC4zIDAgNS42IDAgMTIuM2MwIDUuMyAzLjQgOS44IDguMiAxMS40LjYuMS44LS4zLjgtLjZ2LTJjLTMuMy43LTQtMS42LTQtMS42LS42LTEuNC0xLjQtMS43LTEuNC0xLjctMS4xLS44LjEtLjguMS0uOCAxLjIuMSAxLjggMS4yIDEuOCAxLjIgMS4xIDEuOCAyLjggMS4zIDMuNSAxIC4xLS44LjQtMS4zLjgtMS42LTIuNy0uMy01LjUtMS4zLTUuNS01LjkgMC0xLjMuNS0yLjQgMS4yLTMuMi0uMS0uMy0uNS0xLjUuMS0zLjIgMCAwIDEtLjMgMy4zIDEuMmExMS41IDExLjUgMCAwIDEgNiAwYzIuMy0xLjYgMy4zLTEuMiAzLjMtMS4yLjYgMS43LjIgMi45LjEgMy4yLjguOCAxLjIgMS45IDEuMiAzLjIgMCA0LjYtMi44IDUuNi01LjUgNS45LjQuNC44IDEuMS44IDIuMnYzLjNjMCAuMy4yLjcuOC42QzIwLjYgMjIuMSAyNCAxNy42IDI0IDEyLjMgMjQgNS42IDE4LjYuMyAxMiAuM3oiIC8+CiAgICA8L3N5bWJvbD4KICAgIDxzeW1ib2wgaWQ9Imljb24tdm9sdW1lIiB2aWV3Ym94PSIwIDAgMjQgMjQiPgogICAgICA8cGF0aCBkPSJNNCA5LjV2NWgzLjhMMTMgMTlWNUw3LjggOS41SDR6IiAvPgogICAgICA8cGF0aCBkPSJNMTYuNSA4LjNhNSA1IDAgMCAxIDAgNy40IiAvPgogICAgICA8cGF0aCBkPSJNMTkuMyA1LjdhOS4yIDkuMiAwIDAgMSAwIDEyLjYiIC8+CiAgICA8L3N5bWJvbD4KICAgIDxzeW1ib2wgaWQ9Imljb24tdm9sdW1lLW9mZiIgdmlld2JveD0iMCAwIDI0IDI0Ij4KICAgICAgPHBhdGggZD0iTTQgOS41djVoMy44TDEzIDE5VjVMNy44IDkuNUg0eiIgLz4KICAgICAgPHBhdGggZD0iTTE2LjUgOS41bDUgNU0yMS41IDkuNWwtNSA1IiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLXBsdXMiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik0xMiA1djE0TTUgMTJoMTQiIC8+CiAgICA8L3N5bWJvbD4KICAgIDxzeW1ib2wgaWQ9Imljb24tbWludXMiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxwYXRoIGQ9Ik01IDEyaDE0IiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWZyYW1lIiB2aWV3Ym94PSIwIDAgMjQgMjQiPgogICAgICA8cGF0aCBkPSJNNCA5VjQuNWg1TTIwIDlWNC41aC01TTQgMTV2NC41aDVNMjAgMTV2NC41aC01IiAvPgogICAgPC9zeW1ib2w+CiAgICA8c3ltYm9sIGlkPSJpY29uLWNvcHkiIHZpZXdib3g9IjAgMCAyNCAyNCI+CiAgICAgIDxyZWN0IHg9IjkiIHk9IjkiIHdpZHRoPSIxMSIgaGVpZ2h0PSIxMSIgcng9IjEuNiIgLz4KICAgICAgPHBhdGggZD0iTTYgMTVINWExLjYgMS42IDAgMCAxLTEuNi0xLjZWNUExLjYgMS42IDAgMCAxIDUgMy40aDguNEExLjYgMS42IDAgMCAxIDE1IDV2MSIgLz4KICAgIDwvc3ltYm9sPgogIDwvZGVmcz4KPC9zdmc+)

B Borderline

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBpY29uLXNvdW5kLW9uIj48dXNlIGhyZWY9IiNpY29uLXZvbHVtZSIgLz48L3N2Zz4=) ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBpY29uLXNvdW5kLW9mZiI+PHVzZSBocmVmPSIjaWNvbi12b2x1bWUtb2ZmIiAvPjwvc3ZnPg==)

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBpY29uLXRvLWxpZ2h0Ij48dXNlIGhyZWY9IiNpY29uLXN1biIgLz48L3N2Zz4=) ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBpY29uLXRvLWRhcmsiPjx1c2UgaHJlZj0iI2ljb24tbW9vbiIgLz48L3N2Zz4=)

[![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1naXRodWIiIC8+PC9zdmc+)](https://github.com/ar-puuk/borderline)

US Geography · No. 01

# Borderline

borderline playable, if you squint

39.8283° N  98.5795° W

Name a state, click its outline. Or drop into one state and call its counties, parishes, and boroughs by name. No interior borders shown — just the shape, and how well you know it.

Mode

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1waW4iIC8+PC9zdmc+) States

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1ncmlkIiAvPjwvc3ZnPg==) Counties

Difficulty

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1sZWFmIiAvPjwvc3ZnPg==) Easy

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1mbGFtZSIgLz48L3N2Zz4=) Hard

Easy keeps every answered state/county marked on the map. Hard clears each answer once you move on.

Timing

Untimed

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1jbG9jayIgLz48L3N2Zz4=) Blitz · 60s

Blitz races the clock instead of a round count — answer as many as you can before time runs out.

Pick a state

Alabama

Rounds

10

25

All

You struggle most with

Play ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1hcnJvdy1yaWdodCIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBpZD0iYnRuLWNvcHktc2V0dXAtdXNlIiBocmVmPSIjaWNvbi1jb3B5IiAvPjwvc3ZnPg==)

Map data: US Census Bureau via [us-atlas](https://github.com/topojson/us-atlas).

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1hcnJvdy1sZWZ0IiAvPjwvc3ZnPg==) Quit

Find —

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBodWQtaWNvbiI+PHVzZSBocmVmPSIjaWNvbi10cm9waHkiIC8+PC9zdmc+) 0 score ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBodWQtaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1jbG9jayIgLz48L3N2Zz4=) 60 sec ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBodWQtaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1mbGFnIiAvPjwvc3ZnPg==) 0/0 round ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBodWQtaWNvbiI+PHVzZSBocmVmPSIjaWNvbi16YXAiIC8+PC9zdmc+) 0 streak

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1wbHVzIiAvPjwvc3ZnPg==)

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1taW51cyIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1mcmFtZSIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiBmZWVkYmFjay1pY29uIj48dXNlIGhyZWY9IiNpY29uLXgtY2lyY2xlIiAvPjwvc3ZnPg==)

Next

Outline map used for click-based guessing. Scroll or pinch to zoom in on tricky shapes, drag to pan while zoomed in. Screen reader users can play with sighted assistance; each guess result is announced above.

Round complete

0% 0 / 0

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1yZWZyZXNoIiAvPjwvc3ZnPg==) Play again

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1zbGlkZXJzIiAvPjwvc3ZnPg==) Change mode

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1jb3B5IiAvPjwvc3ZnPg==) Copy result

### ![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi14LWNpcmNsZSIgLz48L3N2Zz4=) Missed

![](data:image/svg+xml;base64,PHN2ZyBjbGFzcz0iaWNvbiI+PHVzZSBocmVmPSIjaWNvbi1yZWZyZXNoIiAvPjwvc3ZnPg==) Retry these

[ Open app](https://ar-puuk.github.io/borderline/) [ GitHub](https://github.com/ar-puuk/borderline)

## 2 The idea: no interior borders

Most map quizzes show you every state line and ask you to pick one. That turns the game into shape recognition with a lot of help: once you have found the neighbours, the answer is the only blank piece left. Borderline draws only the outer outline. In States mode you see the outline of the country and nothing inside it; in Counties mode you pick a state, the map zooms to that state’s outline, and again there are no county lines. You have to know roughly where Kansas is, not just what it looks like.

## 3 How it plays

- **States mode**: click inside the named state to score. Miss, and the correct state is highlighted in red and your click is marked, so you can see how far off you were.
- **Counties mode**: you get county names, or the locally correct equivalent: parishes in Louisiana, boroughs and census areas in Alaska, and independent cities in Virginia, Maryland, Missouri and Nevada.
- **Easy or Hard**: Easy keeps every answered shape on the map (green for a hit, red with a diagonal hatch for a miss) as a running record of the game; Hard clears it between guesses.
- **Untimed or Blitz**: choose 10, 25 or all rounds, or race a 60-second clock. Counties mode hides round counts a state can’t fill: county totals run from 3 in Delaware to 254 in Texas, so Delaware only offers “All”.
- **Zoom and pan** for fiddly shapes like tiny islands and thin coastal counties: scroll or pinch to zoom, drag to pan, or use the on-map buttons. The view resets every round.

The game remembers your best score per mode, round count, state and difficulty in `localStorage`, and across all your games it keeps a per-place miss rate. Once something has been asked at least twice and you keep getting it wrong, it shows up in a “you struggle most with” list on the start screen. At the end of a game, **Retry these** replays just what you missed, and **Copy result** puts a Wordle-style summary (score, a green and red grid of the rounds in order, and a link) on your clipboard.

The start screen’s settings are also mirrored into the URL, so the address bar is always a link to the current setup. For example, `?mode=counties&state=Texas&difficulty=hard&rounds=25&play=1` drops you straight into 25 rounds of Texas counties on Hard.

## 4 Under the hood

Borderline is pure static HTML, CSS and JavaScript (ES modules): no build step, no server, no CDN, built to live on GitHub Pages. The map is drawn on a `<canvas>`. Boundary data comes from the U.S. Census Bureau via [us-atlas](https://github.com/topojson/us-atlas), which packages TIGER/Line boundaries as TopoJSON. The two libraries it needs, `topojson-client` and `d3-geo`, are bundled once with esbuild into small ES modules and committed to the repository, and the fonts (Space Grotesk and Space Mono) are self-hosted. Keeping it dependency-free means it loads fast and is easy for anyone to read and fork.

The code is split into small modules: `game.js` is the round and scoring state machine, `mapData.js` loads the topology and builds prompt lists and labels, `geometry.js` holds projections and hit-testing, `renderer.js` does the canvas drawing, and `stats.js` tracks the lifetime miss rates.

## 5 The interesting parts

### One projection for the country, another for each state

States mode uses us-atlas’s pre-projected Albers USA file, with Alaska and Hawaii already scaled into insets. That is the familiar look for a whole-country map, and since the coordinates are already in pixel space, `d3.geoPath()` can draw them with a null projection.

The first version of Counties mode reused the same Albers coordinates and simply zoomed into one state’s bounding box. It looked wrong. Albers is a conic projection whose meridians converge toward the pole; at continental scale you never notice, but zoomed into a single rectangular state like Utah, Wyoming or Colorado the whole state visibly tilts. The fix was to switch Counties mode to the *unprojected* (longitude and latitude) county file and fit a fresh Web Mercator projection to each state’s extent every time the canvas resizes. Utah and Wyoming came out as clean, upright rectangles.

Alaska then broke that fix. Its Aleutian chain crosses the 180° meridian, and a plain Mercator fit sees a feature spanning almost 360° of longitude, so the state shrinks to a speck. `d3.geoBounds` is spherical-aware and reports a crossing feature with its west edge greater than its east edge, so the fitting function checks for exactly that and rotates the projection to centre on the state’s own longitude before fitting:

``` js
const [[west], [east]] = geoBounds(feature);
const crossesAntimeridian = west > east;
const centerLon = crossesAntimeridian
  ? (((west + east + 360) / 2 + 180) % 360) - 180
  : (west + east) / 2;

return geoMercator().rotate([-centerLon, 0]).fitExtent([[x0, y0], [x1, y1]], feature);
```

A related bug from the very first day went the other way: the bounding-box helper used `d3.geoBounds` on the already-projected Albers coordinates, and since that function expects degrees, it silently returned the whole world. The rule I ended up with is planar bounds for projected data, spherical bounds for longitude and latitude.

### Did the click land inside?

Hit-testing reuses the drawing code. The target feature is turned into a `Path2D` in the same pixel space the renderer draws in, and a tiny off-screen canvas answers `isPointInPath()`. Because the path comes from the same projection as the picture, the answer matches what you see, including holes and multi-part shapes. Zoom and pan sit on top as a separate view transform, which the click handler inverts before the per-mode inversion, so hit-testing stays correct at any zoom level. Pointer handling tells a tap from a drag or pinch with a movement threshold and a pointer count, so panning never registers as a guess.

### County names are not in the data

The county `name` property has no suffix, so the game adds one. Louisiana gets “Parish”. Alaska’s units (boroughs, census areas, consolidated municipalities, and “City and Borough” units like Juneau and Sitka) come from a hand-written lookup table, because they can’t be derived from the data. For the states with independent cities, the FIPS code decides: codes of 500 and above are cities, so the game can tell “Baltimore County” from “Baltimore City” and “Richmond County” from “Richmond City”. As a safety net, any name that still collides within a state gets its FIPS code appended. Washington, D.C. is never prompted (it would be a single-pixel target), though its outline stays on the map.

### Keeping a fast first load

The county file is about 840 KB, against about 80 KB for the states, so it is fetched only the first time you switch to Counties mode. A player who only plays States never downloads it.

### The offline bug that hid a fix

Borderline is an installable progressive web app: a service worker precaches the app shell on first visit and serves it cache-first afterward, so the game works with no network. That design has a sharp edge, which I found the hard way. A fix for Blitz mode getting stuck in a background tab (the countdown relied on `setInterval` ticks, which browsers throttle in hidden tabs; it now checks a wall-clock deadline) was correct in the source but never reached anyone who had already visited, because the cache name had not changed since the service worker was added. Their browsers kept serving the first cached `main.js`. The fix was to bump the cache name, add a regression test that seeds a stale cache and checks it gets purged on activation, and write a note in the README: any commit that touches a precached file must bump the cache name.

### Tests that look at pixels

The game itself has zero dependencies, but there is a dev-only Playwright suite. It checks the things that actually broke during development: hit-testing across all states and the trickiest county cases (Utah’s tilt, Alaska’s antimeridian, Hawaii’s scattered islands, Virginia’s name collisions), Easy and Hard history by reading rendered canvas pixels, pan and zoom correctness, offline loading with the network disabled, and Blitz timing with a mocked clock instead of a real 60-second wait. A few counties are so thin or scattered that a random click point can miss them, so those checks use a 60% floor; a real regression drops the hit rate to zero, which is what the suite is there to catch.

One feature didn’t survive: I added a typed-answer box so screen-reader users could play unaided, then removed it the same day. The prompt already names the place (“Find Kansas”), so typing the name back tested nothing about geography. The canvas does keep a live `aria-label` and announces each result through an `aria-live` region, and every control is a real button.

## 6 What’s next

The data is a fixed vintage from us-atlas: Connecticut still has its eight traditional counties rather than the newer planning regions, and Puerto Rico is not in the Albers files the game uses. Swapping in newer Census data would mean updating that handling.

The code is on [GitHub](https://github.com/ar-puuk/borderline). It is still borderline playable, so bug reports are welcome.

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@online{bhandari2026,
  author = {Bhandari, Pukar},
  title = {Borderline: {A} {U.S.} {Geography} {Guessing} {Game}},
  date = {2026-09-21},
  url = {https://ar-puuk.github.io/posts/borderline/},
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. “Borderline: A U.S. Geography Guessing Game.” September 21. <https://ar-puuk.github.io/posts/borderline/>.
