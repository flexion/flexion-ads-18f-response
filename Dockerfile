FROM shinymayhem/node
COPY . /var/www

USER root
RUN apt-get update && apt-get install -y \
  git-core \
  bzip2 \
  ruby

RUN gem install sass
  
RUN chown -R node .

USER node

RUN npm install; bower install
ENV PORT 80
CMD ["authbind", "--deep", "grunt", "serve:dist"]
