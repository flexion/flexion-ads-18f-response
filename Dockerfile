FROM shinymayhem/node

USER root
RUN apt-get update && apt-get install -y \
  git-core \
  bzip2 \
  libssl-dev \
  ruby

RUN gem install sass

COPY .bowerrc bower.json package.json /var/www/
RUN chown -R node .

USER node

RUN npm install; bower install

COPY . /var/www

ENV PORT 80
CMD ["authbind", "--deep", "grunt", "serve:dist"]
