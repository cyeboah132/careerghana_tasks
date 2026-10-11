/// One list for the whole backend. To add a language, add one line.
class Lang {
  final String code;
  final String name;
  const Lang(this.code, this.name);
}

const languages = <Lang>[
  Lang('en', 'English'),
  Lang('fr', 'French'),
  Lang('es', 'Spanish'),
  Lang('zh', 'Chinese'),
  Lang('tw', 'Twi'), // beta quality
];

Lang? langByCode(String? code) {
  for (final l in languages) {
    if (l.code == code) return l;
  }
  return null;
}
