
printf: extern func

gen: func -> int {
  printf("Oh, I can see it coming\n")
  printf("There it goes\n")
  printf("Almost there\n")
  printf("That's it, now we have it\n")
  42
}

printf("Hey, the value is %d\n", gen())

